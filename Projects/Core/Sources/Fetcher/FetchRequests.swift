//
//  FetchRequests.swift
//  Core
//
//  Created by 김동현 on 10/13/26.
//

import Foundation
import RxSwift

/// 같은 대상의 서버 요청을 하나로 합치고, 마지막으로 서버 값을 받은 시각과 진행 중인 쓰기를 기억합니다.
///
/// Usecase처럼 오래 사는 객체가 하나를 만들고, 같은 데이터를 다루는 Fetcher들이 `sharing(_:key:)`로 함께 씁니다.
/// 쓰기(`update(_:remote:)`, `writeThenRefresh(_:)`)가 진행 중이거나 쓰기 전에 시작된 서버 응답은 오래된 값일 수 있어 저장하지 않습니다.
///
/// ```swift
/// private let groupRequests = FetchRequests<HCGroup>(maxAge: 10)
///
/// Fetcher(...).sharing(groupRequests, key: groupId)
/// ```
public final class FetchRequests<Value> {
    private let maxAge: TimeInterval
    private let now: () -> Date
    private let lock = NSLock()
    private var inFlight: [String: InFlightRequest] = [:]
    private var receivedAt: [String: Date] = [:]
    private var writeVersions: [String: Int] = [:]
    private var pendingWrites: [String: Set<UUID>] = [:]
    private var idleWaiters: [String: [() -> Void]] = [:]

    /// 진행 중인 서버 요청과, 요청을 시작할 때의 쓰기 버전입니다.
    fileprivate struct InFlightRequest {
        let id: UUID
        let request: Single<Value?>
        let writeVersion: Int
    }

    /// - Parameters:
    ///   - maxAge: 서버 값을 받은 뒤 이 시간(초) 안에는 `fetch()`가 서버에 다시 묻지 않습니다. 0이면 매번 묻습니다.
    ///   - now: 지금 시각을 돌려줍니다. 테스트에서 바꿉니다.
    public init(
        maxAge: TimeInterval = 0,
        now: @escaping () -> Date = Date.init
    ) {
        self.maxAge = maxAge
        self.now = now
    }
}

public extension FetchRequests {
    /// 다음 `fetch()`가 최근 값 여부와 상관없이 서버에 묻도록 받은 시각을 지웁니다.
    ///
    /// - Parameter key: 지울 대상.
    func invalidate(key: String) {
        lock.lock()
        defer { lock.unlock() }
        receivedAt[key] = nil
    }
}

extension FetchRequests {
    /// 같은 key의 요청이 진행 중이면 그 결과를 함께 받고, 없으면 새로 요청합니다.
    ///
    /// 쓰기와 겹친 오래된 응답이면 `FetchError.staleResponse`로 끝냅니다.
    ///
    /// - Parameters:
    ///   - key: 같은 대상인지 구분하는 값.
    ///   - request: 새로 요청할 때 쓰는 서버 요청.
    func share(
        key: String,
        request: @escaping () -> Single<Value?>
    ) -> Single<Value?> {
        Single.deferred { [weak self] in
            guard let self = self else {
                return request()
            }
            let inFlightRequest = self.inFlightRequest(key: key, request: request)
            return self.checkingStale(inFlightRequest, key: key)
        }
    }

    /// 마지막으로 서버 값을 받은 지 `maxAge`가 지나지 않았는지 돌려줍니다.
    ///
    /// - Parameter key: 확인할 대상.
    func isFresh(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard
            maxAge > 0,
            let date = receivedAt[key]
        else {
            return false
        }
        return now().timeIntervalSince(date) < maxAge
    }

    /// 쓰기를 시작합니다. 끝날 때까지 이 key의 서버 응답은 저장하지 않습니다.
    ///
    /// - Parameter key: 쓰는 대상.
    /// - Returns: `endWrite(key:token:)`에 넘길 값.
    func beginWrite(key: String) -> UUID {
        lock.lock()
        defer { lock.unlock() }
        let token = UUID()
        pendingWrites[key, default: []].insert(token)
        writeVersions[key, default: 0] += 1
        // 쓰기 전에 시작된 요청에 새 조회가 합류하지 않게 한다
        inFlight[key] = nil
        return token
    }

    /// 쓰기를 끝냅니다. 쓰는 동안 시작된 서버 응답도 저장하지 않습니다.
    ///
    /// 같은 token으로 여러 번 불러도 한 번만 반영합니다.
    ///
    /// - Parameters:
    ///   - key: 쓴 대상.
    ///   - token: `beginWrite(key:)`가 돌려준 값.
    func endWrite(key: String, token: UUID) {
        lock.lock()
        guard pendingWrites[key]?.remove(token) != nil else {
            lock.unlock()
            return
        }
        var waiters: [() -> Void] = []
        if pendingWrites[key]?.isEmpty == true {
            pendingWrites[key] = nil
            waiters = idleWaiters.removeValue(forKey: key) ?? []
        }
        writeVersions[key, default: 0] += 1
        // 쓰는 동안 시작된 요청에 새 조회가 합류하지 않게 한다
        inFlight[key] = nil
        lock.unlock()

        waiters.forEach { $0() }
    }

    /// 진행 중인 쓰기가 모두 끝나면 완료합니다. 쓰기가 없으면 바로 완료합니다.
    ///
    /// 쓰기가 끝난 뒤에 시작한 서버 응답만 저장되므로, 실패한 쓰기를 서버 값으로 바로잡을 때 기다립니다.
    ///
    /// - Parameter key: 기다릴 대상.
    func waitUntilWritesFinish(key: String) -> Completable {
        Completable.create { [weak self] observer in
            guard let self = self else {
                observer(.completed)
                return Disposables.create()
            }
            self.lock.lock()
            guard self.pendingWrites[key] != nil else {
                self.lock.unlock()
                observer(.completed)
                return Disposables.create()
            }
            self.idleWaiters[key, default: []].append {
                observer(.completed)
            }
            self.lock.unlock()
            return Disposables.create()
        }
    }
}

private extension FetchRequests {
    /// 진행 중인 요청을 돌려주거나, 새 요청을 만들어 등록합니다.
    func inFlightRequest(
        key: String,
        request: () -> Single<Value?>
    ) -> InFlightRequest {
        lock.lock()
        defer { lock.unlock() }

        if let inFlightRequest = inFlight[key] {
            return inFlightRequest
        }

        let id = UUID()
        let sharedRequest = request()
            .do(onDispose: { [weak self] in
                self?.finish(key: key, id: id)
            })
            .asObservable()
            .share(replay: 1, scope: .whileConnected)
            .asSingle()
        let inFlightRequest = InFlightRequest(
            id: id,
            request: sharedRequest,
            writeVersion: writeVersions[key, default: 0]
        )
        inFlight[key] = inFlightRequest
        return inFlightRequest
    }

    /// 응답이 쓰기와 겹쳤으면 `FetchError.staleResponse`로 바꾸고, 아니면 받은 시각을 기록합니다.
    func checkingStale(
        _ inFlightRequest: InFlightRequest,
        key: String
    ) -> Single<Value?> {
        inFlightRequest.request
            .flatMap { [weak self] value in
                guard let self = self else {
                    return .just(value)
                }
                guard !self.isStale(key: key, writeVersion: inFlightRequest.writeVersion) else {
                    return .error(FetchError.staleResponse)
                }
                self.markReceived(key: key, hasValue: value != nil)
                return .just(value)
            }
    }

    /// 쓰기가 진행 중이거나, 요청을 시작한 뒤 쓰기가 있었는지 돌려줍니다.
    func isStale(key: String, writeVersion: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return pendingWrites[key] != nil
            || writeVersions[key, default: 0] != writeVersion
    }

    /// 서버 값을 받은 시각을 기록합니다. 서버에 데이터가 없으면 기록을 지웁니다.
    func markReceived(key: String, hasValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        receivedAt[key] = hasValue ? now() : nil
    }

    /// 끝난 요청을 지워 다음 요청이 새로 나가게 합니다. 그사이 다른 요청이 등록됐으면 그대로 둡니다.
    func finish(key: String, id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        guard inFlight[key]?.id == id else {
            return
        }
        inFlight[key] = nil
    }
}
