//
//  SessionObservableTests.swift
//  CoreTests
//
//  Created by 김동현 on 10/13/26.
//

import RxSwift
import XCTest
@testable import Core

/// `SessionContext.asObservable()`이 지금 값과 바뀐 값을 보내고, 구독을 해제하면 관찰을 멈추는지 확인합니다.
final class SessionObservableTests: XCTestCase {

    private struct Profile: Codable, Equatable, CustomStringConvertible {
        var id: String
        var description: String { "Profile(id: \(id))" }
    }

    func test_asObservable_sendsCurrentValueThenChanges() {
        let session = SessionContext<Profile>(storage: FakeUserDefaultsStorage(), storageKey: "profile")
        session.update(Profile(id: "1"))
        var values: [Profile?] = []
        let disposable = session.asObservable()
            .subscribe(onNext: { values.append($0) })

        session.update(Profile(id: "2"))
        session.clear()
        disposable.dispose()

        XCTAssertEqual(values, [Profile(id: "1"), Profile(id: "2"), nil])
    }

    func test_asObservable_stopsObserving_whenDisposed() {
        let session = SessionContext<Profile>(storage: FakeUserDefaultsStorage(), storageKey: "profile")
        var values: [Profile?] = []
        let disposable = session.asObservable()
            .subscribe(onNext: { values.append($0) })

        disposable.dispose()
        session.update(Profile(id: "1"))

        XCTAssertEqual(values, [nil])
    }
}
