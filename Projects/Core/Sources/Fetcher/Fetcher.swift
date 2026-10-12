//
//  Fetcher.swift
//  Core
//
//  Created by 김동현 on 10/12/26.
//

import RxSwift

/*
 [사용법]
 let fetcher = Fetcher(
     local: { groupSession.entity },                              // 지금 저장된 값
     remote: { groupRepository.fetchGroup(groupId: groupId) },    // nil = 서버에 없음, 에러 = 확인 실패
     updateLocal: { groupSession.update($0.toSession()) },        // 서버 값 저장
     removeLocal: { groupSession.clear() }                        // 서버에 없을 때 캐시 삭제
 )

 // 캐시를 먼저 보내고 서버 값으로 갱신
 fetcher.fetch()    // (.loading, 캐시) → (.success, 서버 값) | (.notFound, nil) | (.failure, 캐시)

 // 캐시 없이 서버 값만 받아 저장 (쓰기 후 다시 읽기)
 fetcher.refresh()  // (.success, 서버 값) | (.notFound, nil) | (.failure, 캐시)

 // 기존 Observable<Value> 모양으로 사용
 fetcher.fetch().fetchedValues()
 */

/// Fetcher가 전달하는 조회 단계입니다.
public enum FetchStatus {
    /// 서버에 묻는 중입니다. 값은 캐시이며 없으면 `nil`입니다.
    case loading
    /// 서버 값을 받아 저장했습니다. 값은 서버 값입니다.
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

/// `fetchedValues()`가 보내는 에러입니다.
public enum FetchError: Error, Equatable {
    /// 서버에 데이터가 없습니다.
    case notFound
}

/// 로컬 캐시를 먼저 보여 주고 서버 값으로 갱신하는 조회 정책입니다.
///
/// 서버 응답을 값·없음(`nil`)·실패(에러)로 나눠 처리합니다.
/// - 값: `updateLocal`로 저장합니다.
/// - 없음: `removeLocal`로 캐시를 지웁니다.
/// - 실패: 캐시를 그대로 둡니다.
public struct Fetcher<Value> {
    private let local: () -> Value?
    private let remote: () -> Single<Value?>
    private let updateLocal: (Value) -> Void
    private let removeLocal: () -> Void

    /// 캐시와 서버를 다루는 클로저로 Fetcher를 만듭니다.
    ///
    /// - Parameters:
    ///   - local: 지금 저장된 값을 읽습니다. 없으면 `nil`입니다.
    ///   - remote: 서버에 값을 요청합니다. 서버에 데이터가 없으면 `nil`, 확인하지 못하면 에러를 보냅니다.
    ///   - updateLocal: 서버 값을 저장합니다.
    ///   - removeLocal: 서버에 데이터가 없을 때 캐시를 지웁니다.
    public init(
        local: @escaping () -> Value?,
        remote: @escaping () -> Single<Value?>,
        updateLocal: @escaping (Value) -> Void,
        removeLocal: @escaping () -> Void
    ) {
        self.local = local
        self.remote = remote
        self.updateLocal = updateLocal
        self.removeLocal = removeLocal
    }
}

public extension Fetcher {
    /// 캐시를 `.loading`으로 먼저 보내고 서버 결과를 이어서 보냅니다.
    ///
    /// 구독할 때 캐시를 읽고 서버에 요청합니다. 서버 결과를 보낸 뒤 끝납니다.
    func fetch() -> Observable<FetchResult<Value>> {
        Observable.deferred {
            requestRemote()
                .startWith(
                    FetchResult(status: .loading, value: local())
                )
        }
    }

    /// 캐시를 보내지 않고 서버 결과만 보냅니다.
    ///
    /// 서버에 쓴 직후 최신 값을 다시 읽을 때 사용합니다. 결과 하나를 보낸 뒤 끝납니다.
    func refresh() -> Observable<FetchResult<Value>> {
        Observable.deferred {
            requestRemote()
        }
    }
}

private extension Fetcher {
    /// 서버 결과를 캐시에 반영하고 조회 단계로 바꿉니다.
    func requestRemote() -> Observable<FetchResult<Value>> {
        remote()
            .do(onSuccess: { value in
                if let value {
                    updateLocal(value)
                } else {
                    removeLocal()
                }
            })
            .map { value in
                FetchResult(
                    status: value == nil ? .notFound : .success,
                    value: value
                )
            }
            .catch { error in
                .just(FetchResult(status: .failure(error), value: local()))
            }
            .asObservable()
    }
}

public extension ObservableType {
    /// 조회 단계를 값 스트림으로 바꿉니다.
    ///
    /// 기존 `Observable<Value>`를 쓰는 호출부를 위한 변환입니다.
    /// - `.loading`, `.success`: 값이 있으면 보내고, 없으면 건너뜁니다.
    /// - `.notFound`: `FetchError.notFound`로 끝냅니다.
    /// - `.failure`: 그 에러로 끝냅니다.
    func fetchedValues<Value>() -> Observable<Value> where Element == FetchResult<Value> {
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
