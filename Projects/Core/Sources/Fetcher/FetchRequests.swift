//
//  FetchRequests.swift
//  Core
//
//  Created by 김동현 on 10/13/26.
//

import Foundation
import RxSwift

/// 같은 대상의 서버 요청을 하나로 합치고, 마지막으로 서버 값을 받은 시각을 기억합니다.
///
/// Usecase처럼 오래 사는 객체가 하나를 만들고, 같은 데이터를 다루는 Fetcher들이 `sharing(_:key:)`로 함께 씁니다.
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
    private var inFlight: [String: Single<Value?>] = [:]
    private var receivedAt: [String: Date] = [:]

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
            return self.sharedRequest(key: key, request: request)
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
}

private extension FetchRequests {
    /// 진행 중인 요청을 돌려주거나, 새 요청을 만들어 등록합니다.
    func sharedRequest(
        key: String,
        request: () -> Single<Value?>
    ) -> Single<Value?> {
        lock.lock()
        defer { lock.unlock() }

        if let inFlightRequest = inFlight[key] {
            return inFlightRequest
        }

        let sharedRequest = request()
            .do(
                onSuccess: { [weak self] value in
                    self?.markReceived(key: key, hasValue: value != nil)
                },
                onDispose: { [weak self] in
                    self?.finish(key: key)
                }
            )
            .asObservable()
            .share(replay: 1, scope: .whileConnected)
            .asSingle()
        inFlight[key] = sharedRequest
        return sharedRequest
    }

    /// 서버 값을 받은 시각을 기록합니다. 서버에 데이터가 없으면 기록을 지웁니다.
    func markReceived(key: String, hasValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        receivedAt[key] = hasValue ? now() : nil
    }

    /// 끝난 요청을 지워 다음 요청이 새로 나가게 합니다.
    func finish(key: String) {
        lock.lock()
        defer { lock.unlock() }
        inFlight[key] = nil
    }
}
