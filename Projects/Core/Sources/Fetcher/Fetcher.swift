//
//  Fetcher.swift
//  Core
//
//  Created by 김동현 on 10/12/26.
//

import Foundation
import RxSwift

/*
 [사용법]
 let fetcher = Fetcher(
     local: { groupSession.entity },                              // 지금 저장된 값
     observeLocal: { groupSession.asObservable().map { $0?.toEntity() } }, // 저장된 값의 변화
     remote: { groupRepository.fetchGroup(groupId: groupId) },    // nil = 서버에 없음, 에러 = 확인 실패
     updateLocal: { groupSession.update($0.toSession()) },        // 서버 값 저장
     removeLocal: { groupSession.clear() },                       // 서버에 없을 때 캐시 삭제
     cleanUpNotFound: { leaveMissingGroup() },                    // 서버에 없을 때 서버 정리까지 해야 하면
     isCurrent: { userSession.groupId == groupId }                // 응답이 왔을 때 아직 같은 대상인지
 )
 .timeout(.seconds(15))                                           // 서버가 응답하지 않으면 실패
 .sharing(groupRequests, key: groupId)                            // 같은 요청 합치기, 최근 값이면 서버 생략
 .logging("Group")                                                // 단계별 로그 (Debug 빌드)

 fetcher.fetch()      // 캐시를 먼저 보내고 서버 값으로 갱신
 fetcher.refresh()    // 캐시 없이 서버 값만 받아 저장 (쓰기 후 다시 읽기)
 fetcher.observe()    // 저장된 값이 바뀔 때마다 받기 (서버에 묻지 않음)
 fetcher.update({ $0.isPushEnabled = true }, remote: { repository.updateUser(user: $0) })
                      // 로컬을 먼저 바꾸고 서버에 쓰기, 실패하면 되돌리기

 fetcher.fetch().fetchedValues()  // 기존 Observable<Value> 모양으로 사용
 */

/// Fetcher가 전달하는 조회 단계입니다.
public enum FetchStatus {
    /// 서버에 묻는 중입니다. 값은 캐시이며 없으면 `nil`입니다.
    case loading
    /// 서버 값을 받아 저장했습니다. 값은 서버 값입니다. 최근에 받은 값이라 서버를 건너뛰었다면 캐시입니다.
    case success
    /// 서버에 데이터가 없어 캐시를 지웠습니다. 값은 `nil`입니다.
    case notFound
    /// 서버에 확인하지 못했습니다. 캐시는 그대로이고 값은 캐시입니다.
    case failure(Error)
}

/// 조회 단계와 그 시점에 화면에 보여 줄 값입니다.
public struct FetchResult<Value> {
    /// 조회 단계입니다.
    public let status: FetchStatus

    /// 그 단계에서 보여 줄 값입니다. 캐시가 없거나 서버에 데이터가 없으면 `nil`입니다.
    public let value: Value?

    public init(status: FetchStatus, value: Value?) {
        self.status = status
        self.value = value
    }
}

/// `Fetcher`가 보내는 에러입니다.
public enum FetchError: Error, Equatable {
    /// 서버에 데이터가 없습니다.
    case notFound
    /// 정해진 시간 안에 서버가 응답하지 않았습니다.
    case timeout
    /// 쓰기 전에 바꿀 캐시가 없습니다.
    case missingLocal
}

/// 로컬 캐시를 먼저 보여 주고 서버 값으로 갱신하는 조회 정책입니다.
///
/// 서버 응답을 값·없음(`nil`)·실패(에러)로 나눠 처리합니다.
/// - 값: `updateLocal`로 저장합니다.
/// - 없음: `removeLocal`로 캐시를 지우고, `cleanUpNotFound`가 있으면 끝날 때까지 기다립니다.
/// - 실패: 캐시를 그대로 둡니다.
///
/// 응답이 왔을 때 `isCurrent`가 `false`면(요청한 유저·그룹이 그사이 바뀜) 응답을 버립니다.
/// 캐시를 바꾸지 않고 결과도 보내지 않은 채 끝납니다.
public struct Fetcher<Value> {
    private var local: () -> Value?
    private var observeLocal: () -> Observable<Value?>
    private var remote: () -> Single<Value?>
    private var updateLocal: (Value) -> Void
    private var removeLocal: () -> Void
    private var cleanUpNotFound: (() -> Completable)?
    private var isCurrent: () -> Bool
    private var isFresh: () -> Bool
    private var log: (String, Bool) -> Void

    /// 캐시와 서버를 다루는 클로저로 Fetcher를 만듭니다.
    ///
    /// - Parameters:
    ///   - local: 지금 저장된 값을 읽습니다. 없으면 `nil`입니다.
    ///   - observeLocal: 저장된 값을 먼저 보내고 바뀔 때마다 보냅니다. 생략하면 `observe()`가 지금 값만 보내고 끝납니다.
    ///   - remote: 서버에 값을 요청합니다. 서버에 데이터가 없으면 `nil`, 확인하지 못하면 에러를 보냅니다.
    ///   - updateLocal: 서버 값을 저장합니다.
    ///   - removeLocal: 서버에 데이터가 없을 때 캐시를 지웁니다.
    ///   - cleanUpNotFound: 서버에 데이터가 없을 때 캐시를 지운 뒤 할 정리입니다. 서버 쓰기처럼 기다려야 하는 일을 넣습니다.
    ///   - isCurrent: 응답을 반영해도 되는지 확인합니다. 요청한 대상이 지금 캐시의 대상과 다르면 `false`입니다.
    public init(
        local: @escaping () -> Value?,
        observeLocal: (() -> Observable<Value?>)? = nil,
        remote: @escaping () -> Single<Value?>,
        updateLocal: @escaping (Value) -> Void,
        removeLocal: @escaping () -> Void,
        cleanUpNotFound: (() -> Completable)? = nil,
        isCurrent: @escaping () -> Bool = { true }
    ) {
        self.local = local
        self.observeLocal = observeLocal ?? {
            Observable.deferred { .just(local()) }
        }
        self.remote = remote
        self.updateLocal = updateLocal
        self.removeLocal = removeLocal
        self.cleanUpNotFound = cleanUpNotFound
        self.isCurrent = isCurrent
        self.isFresh = { false }
        self.log = { _, _ in }
    }
}

// MARK: - 조회

public extension Fetcher {
    /// 캐시를 `.loading`으로 먼저 보내고 서버 결과를 이어서 보냅니다.
    ///
    /// 구독할 때 캐시를 읽고 서버에 요청합니다. 서버 결과를 보낸 뒤 끝납니다.
    /// - 요청한 대상이 바뀌어 응답을 버리면 `.loading`만 보내고 끝납니다.
    /// - `sharing(_:key:)`로 정한 시간 안에 서버 값을 받았다면 서버에 묻지 않고 캐시를 `.success`로 보냅니다.
    func fetch() -> Observable<FetchResult<Value>> {
        Observable.deferred {
            // 캐시를 먼저 읽은 뒤 서버에 요청한다
            let cached = local()
            let loading = FetchResult(status: .loading, value: cached)

            if cached != nil, isFresh() {
                log("최근에 받은 값이라 서버 요청 생략", false)
                return .of(loading, FetchResult(status: .success, value: cached))
            }
            return requestRemote().startWith(loading)
        }
    }

    /// 캐시를 보내지 않고 서버 결과만 보냅니다.
    ///
    /// 서버에 쓴 직후나 당겨서 새로고침할 때 씁니다. 최근에 받은 값이 있어도 서버에 묻습니다.
    /// 결과 하나를 보낸 뒤 끝납니다. 요청한 대상이 바뀌어 응답을 버리면 아무것도 보내지 않고 끝납니다.
    func refresh() -> Observable<FetchResult<Value>> {
        Observable.deferred {
            requestRemote()
        }
    }

    /// 저장된 값을 먼저 보내고, 저장된 값이 바뀔 때마다 보냅니다. 서버에는 묻지 않습니다.
    ///
    /// 다른 화면이 서버 값이나 쓰기 결과를 저장하면 구독한 화면이 바로 받습니다.
    /// 끝나지 않는 스트림이므로 화면이 사라질 때 구독을 해제합니다.
    func observe() -> Observable<Value?> {
        Observable.deferred {
            observeLocal()
        }
    }
}

public extension Fetcher where Value: Equatable {
    /// 저장된 값을 먼저 보내고, 값이 달라질 때만 다시 보냅니다. 서버에는 묻지 않습니다.
    ///
    /// 같은 값을 다시 저장해도 화면에 다시 보내지 않습니다.
    func observe() -> Observable<Value?> {
        Observable.deferred {
            observeLocal()
        }
        .distinctUntilChanged()
    }
}

// MARK: - 쓰기

public extension Fetcher {
    /// 로컬을 먼저 바꾸고 서버에 씁니다. 서버 쓰기가 실패하면 로컬을 원래 값으로 되돌립니다.
    ///
    /// 화면은 서버 응답을 기다리지 않고 바뀐 값을 바로 보여 줍니다. 실패하면 되돌린 값이 다시 저장됩니다.
    /// 그사이 요청한 대상이 바뀌었으면(`isCurrent`가 `false`) 되돌리지 않습니다.
    ///
    /// - Parameters:
    ///   - change: 저장된 값을 바꾸는 방법.
    ///   - write: 바뀐 값을 서버에 쓰는 요청.
    /// - Returns: 바뀐 값. 바꿀 캐시가 없으면 `FetchError.missingLocal`, 서버 쓰기가 실패하면 그 에러로 끝납니다.
    func update(
        _ change: @escaping (inout Value) -> Void,
        remote write: @escaping (Value) -> Single<Void>
    ) -> Single<Value> {
        Single.deferred {
            guard let original = local() else {
                return .error(FetchError.missingLocal)
            }

            var changed = original
            change(&changed)
            updateLocal(changed)

            return write(changed)
                .map { changed }
                .do(onSuccess: { _ in
                    log("쓰기: 서버 반영 완료", false)
                })
                .catch { error in
                    if isCurrent() {
                        log("쓰기 실패: 캐시를 원래 값으로 되돌림 (\(error))", true)
                        updateLocal(original)
                    }
                    return .error(error)
                }
        }
    }
}

// MARK: - 꾸미기

public extension Fetcher {
    /// 서버가 정해진 시간 안에 응답하지 않으면 `FetchError.timeout`으로 실패하는 Fetcher를 돌려줍니다.
    ///
    /// 오프라인처럼 응답이 오지 않는 상황에서 `.loading`이 끝나지 않는 것을 막습니다.
    ///
    /// - Parameters:
    ///   - dueTime: 기다릴 시간.
    ///   - scheduler: 시간을 재는 스케줄러. 테스트에서 바꿉니다.
    func timeout(
        _ dueTime: RxTimeInterval,
        scheduler: SchedulerType = MainScheduler.instance
    ) -> Fetcher<Value> {
        var fetcher = self
        fetcher.remote = {
            remote()
                .timeout(dueTime, scheduler: scheduler)
                .catch { error in
                    if case RxError.timeout = error {
                        return .error(FetchError.timeout)
                    }
                    return .error(error)
                }
        }
        return fetcher
    }

    /// 같은 대상의 서버 요청을 하나로 합치고, 최근에 받은 값이면 `fetch()`가 서버를 건너뛰는 Fetcher를 돌려줍니다.
    ///
    /// 여러 화면이 동시에 같은 그룹을 요청하면 서버 요청 하나의 결과를 함께 받습니다.
    /// `FetchRequests`를 만들 때 정한 시간 안에 서버 값을 받았다면 `fetch()`는 캐시를 `.success`로 보냅니다.
    /// `refresh()`는 항상 서버에 묻습니다.
    ///
    /// - Parameters:
    ///   - requests: 진행 중인 요청과 마지막으로 받은 시각을 기억하는 저장소. 오래 사는 객체(Usecase)가 가집니다.
    ///   - key: 같은 대상인지 구분하는 값. (예: 그룹 ID)
    func sharing(
        _ requests: FetchRequests<Value>,
        key: String
    ) -> Fetcher<Value> {
        var fetcher = self
        fetcher.remote = {
            requests.share(key: key, request: remote)
        }
        fetcher.isFresh = {
            requests.isFresh(key: key)
        }
        return fetcher
    }

    /// 캐시 읽기, 서버 요청·응답, 캐시 저장·삭제, 응답 버림을 `Logger`로 남기는 Fetcher를 돌려줍니다.
    ///
    /// 결과와 캐시 처리는 바꾸지 않습니다. 개인정보가 남지 않도록 값의 내용 대신
    /// 있음·없음만 남깁니다. Release 빌드에서는 로그 없이 원래 Fetcher를 돌려줍니다.
    ///
    /// ```swift
    /// Fetcher(...).logging("Group").fetch()
    /// // [Group] 캐시 읽기: 있음 → [Group] 서버 요청 → [Group] 서버 응답: 값 → [Group] 캐시 저장
    /// ```
    ///
    /// - Parameter label: 로그 앞에 붙일 이름. 어느 Fetcher의 로그인지 구분합니다.
    func logging(
        _ label: String,
        file: String = #file,
        line: Int = #line
    ) -> Fetcher<Value> {
        #if DEBUG
        let log: (String, Bool) -> Void = { message, isWarning in
            let message = "[\(label)] \(message)"
            if isWarning {
                Logger.w(message, file: file, line: line, function: "Fetcher")
            } else {
                Logger.d(message, file: file, line: line, function: "Fetcher")
            }
        }

        var fetcher = self
        fetcher.log = log
        fetcher.local = {
            let value = local()
            log("캐시 읽기: \(value == nil ? "없음" : "있음")", false)
            return value
        }
        fetcher.remote = {
            remote().do(
                onSuccess: { value in
                    log("서버 응답: \(value == nil ? "없음" : "값")", false)
                },
                onError: { error in
                    log("서버 응답: 실패 (\(error))", true)
                },
                onSubscribe: {
                    log("서버 요청", false)
                }
            )
        }
        fetcher.updateLocal = { value in
            log("캐시 저장", false)
            updateLocal(value)
        }
        fetcher.removeLocal = {
            log("캐시 삭제", false)
            removeLocal()
        }
        if let cleanUpNotFound {
            fetcher.cleanUpNotFound = {
                cleanUpNotFound().do(
                    onError: { error in
                        log("없음 뒷정리 실패 (\(error))", true)
                    },
                    onCompleted: {
                        log("없음 뒷정리 완료", false)
                    },
                    onSubscribe: {
                        log("없음 뒷정리 시작", false)
                    }
                )
            }
        }
        fetcher.isCurrent = {
            let current = self.isCurrent()
            if !current {
                log("요청 대상이 바뀌어 결과를 반영하지 않음", true)
            }
            return current
        }
        return fetcher
        #else
        return self
        #endif
    }
}

private extension Fetcher {
    /// 서버 결과를 캐시에 반영하고 조회 단계로 바꿉니다. 요청한 대상이 바뀌었으면 결과를 버립니다.
    func requestRemote() -> Observable<FetchResult<Value>> {
        remote()
            .asObservable()
            .flatMap { value -> Observable<FetchResult<Value>> in
                guard isCurrent() else {
                    return .empty()
                }
                guard let value else {
                    removeLocal()
                    let notFound = Observable.just(
                        FetchResult<Value>(status: .notFound, value: nil)
                    )
                    // 서버 정리가 끝나야 없음으로 끝낸다. 정리가 실패하면 아래 catch에서 실패로 바뀐다
                    guard let cleanUpNotFound else {
                        return notFound
                    }
                    return cleanUpNotFound().andThen(notFound)
                }
                updateLocal(value)
                return .just(FetchResult(status: .success, value: value))
            }
            .catch { error in
                // 지금 캐시는 다른 대상의 값이므로 실패와 함께 보내지 않는다
                guard isCurrent() else {
                    return .empty()
                }
                return .just(FetchResult(status: .failure(error), value: local()))
            }
    }
}

// MARK: - 값만 꺼내기

public extension ObservableType {
    /// 조회 단계를 값 스트림으로 바꿉니다.
    ///
    /// 기존 `Observable<Value>`를 쓰는 호출부를 위한 변환입니다.
    /// - `.loading`, `.success`: 값이 있으면 보내고, 없으면 건너뜁니다.
    /// - `.notFound`: `FetchError.notFound`로 끝냅니다.
    /// - `.failure`: 그 에러로 끝냅니다.
    func fetchedValues<Value>() -> Observable<Value> where Element == FetchResult<Value> {
        extractFetchedValues()
    }

    /// 조회 단계를 값 스트림으로 바꾸고, 바로 앞과 같은 값은 다시 보내지 않습니다.
    ///
    /// 캐시와 서버 값이 같으면 한 번만 보냅니다. 단계별 처리는 `Equatable`이 아닌 값과 같습니다.
    func fetchedValues<Value: Equatable>() -> Observable<Value> where Element == FetchResult<Value> {
        extractFetchedValues()
            .distinctUntilChanged()
    }
}

private extension ObservableType {
    /// 단계에서 값을 꺼내고, 없음·실패는 에러로 바꿉니다.
    func extractFetchedValues<Value>() -> Observable<Value> where Element == FetchResult<Value> {
        concatMap { result -> Observable<Value> in
            switch result.status {
            case .loading, .success:
                return result.value.map(Observable.just) ?? .empty()
            case .notFound:
                return .error(FetchError.notFound)
            case let .failure(error):
                return .error(error)
            }
        }
    }
}
