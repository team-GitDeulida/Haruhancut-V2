//
//  NetworkReachabilityTests.swift
//  DataTests
//
//  Created by 김동현 on 10/14/26.
//

import Network
import RxSwift
import UIKit
import XCTest
@testable import Data

/// 네트워크 상태에 따라 쓰기를 시작하거나, 시작하지 않고 `offline`으로 끝내는지 확인합니다.
final class NetworkReachabilityTests: XCTestCase {
    private var isConnected: PublishSubject<Bool>!
    private var scheduler: HistoricalScheduler!
    private var disposeBag: DisposeBag!
    private var sut: NetworkReachability!

    override func setUp() {
        super.setUp()
        isConnected = PublishSubject<Bool>()
        scheduler = HistoricalScheduler()
        disposeBag = DisposeBag()
        sut = NetworkReachability(
            isConnected: isConnected,
            startupGrace: .seconds(1),
            scheduler: scheduler
        )
    }

    override func tearDown() {
        sut = nil
        disposeBag = nil
        scheduler = nil
        isConnected = nil
        super.tearDown()
    }

    // MARK: - requireConnection

    func testRequireConnectionCompletesWhenConnected() {
        isConnected.onNext(true)

        let recorder = record(sut.requireConnection())

        XCTAssertTrue(recorder.isCompleted)
    }

    func testRequireConnectionFailsWithOfflineWhenDisconnected() {
        isConnected.onNext(true)
        isConnected.onNext(false)

        let recorder = record(sut.requireConnection())

        XCTAssertTrue(isOffline(recorder.error))
    }

    func testRequireConnectionCompletesAgainAfterReconnect() {
        isConnected.onNext(false)
        isConnected.onNext(true)

        let recorder = record(sut.requireConnection())

        XCTAssertTrue(recorder.isCompleted)
    }

    func testRequireConnectionWaitsForFirstStatus() {
        let recorder = record(sut.requireConnection())

        XCTAssertFalse(recorder.isCompleted)
        XCTAssertNil(recorder.error)

        isConnected.onNext(false)

        XCTAssertTrue(isOffline(recorder.error))
    }

    func testRequireConnectionDoesNotBlockWhenStatusIsUnknownAfterStartupGrace() {
        let recorder = record(sut.requireConnection())

        scheduler.advanceTo(Date(timeIntervalSince1970: 1))

        // 상태를 모르면 예전처럼 쓰기를 막지 않습니다.
        XCTAssertTrue(recorder.isCompleted)
    }

    // MARK: - 네트워크 상태

    func testOnlyUnsatisfiedPathCountsAsDisconnected() {
        XCTAssertTrue(NetworkReachability.isConnected(.satisfied))
        // 주문형 VPN처럼 요청이 오면 연결을 맺는 상태는 막지 않습니다.
        XCTAssertTrue(NetworkReachability.isConnected(.requiresConnection))
        XCTAssertFalse(NetworkReachability.isConnected(.unsatisfied))
    }

    // MARK: - 쓰기

    func testDatabaseWriteFailsWithOfflineWithoutStartingWhenDisconnected() {
        let manager = FirebaseAuthManager(
            apnsTokenProvider: { nil },
            fcmTokenProvider: { completion in completion(nil, nil) },
            connection: { self.disconnectedConnection() }
        )

        let recorder = record(manager.deleteValue(path: "groups/group").asCompletable())

        XCTAssertTrue(isOffline(recorder.error))
    }

    func testStorageWriteFailsWithOfflineWithoutStartingWhenDisconnected() {
        let manager = FirebaseStorageManager(
            connection: { self.disconnectedConnection() }
        )

        let recorder = record(manager.deleteImage(path: "groups/group/images/post.jpg").asCompletable())

        XCTAssertTrue(isOffline(recorder.error))
    }
}

// MARK: - Helpers

private extension NetworkReachabilityTests {
    /// 네트워크가 끊긴 연결입니다.
    func disconnectedConnection() -> NetworkReachability {
        NetworkReachability(
            isConnected: .just(false),
            scheduler: scheduler
        )
    }

    func record(_ completable: Completable) -> Recorder {
        let recorder = Recorder()
        completable
            .subscribe(
                onCompleted: { recorder.isCompleted = true },
                onError: { recorder.error = $0 }
            )
            .disposed(by: disposeBag)
        return recorder
    }

    func isOffline(_ error: Error?) -> Bool {
        if case FirebaseError.offline? = error {
            return true
        }
        return false
    }
}

/// 구독 결과를 모읍니다.
private final class Recorder {
    var error: Error?
    var isCompleted = false
}
