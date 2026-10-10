//
//  UserDefaultsStorageTests.swift
//  CoreTests
//
//  Created by 김동현 on 10/10/26.
//

import XCTest
@testable import Core

final class UserDefaultsStorageTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var sut: UserDefaultsStorage!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsStorageTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        sut = UserDefaultsStorage(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_write_overwritesData_andReadReturnsIt() {
        sut.write(Data("old".utf8), to: "session.user")
        sut.write(Data("new".utf8), to: "session.user")

        XCTAssertEqual(sut.read("session.user"), Data("new".utf8))
        XCTAssertNil(sut.read("missing"))
    }

    func test_remove_deletesValue_andIgnoresMissingKey() {
        sut.write(Data("user".utf8), to: "session.user")

        sut.remove("session.user")
        sut.remove("missing")

        XCTAssertNil(sut.read("session.user"))
        XCTAssertNil(defaults.object(forKey: "session.user"))
    }

    func test_setAndGet_storePlainValues() {
        sut.set("user_123", forKey: "userId")
        sut.set(true, forKey: "isLoggedIn")

        XCTAssertEqual(sut.get(forKey: "userId"), "user_123")
        XCTAssertEqual(sut.get(forKey: "isLoggedIn"), true)
        // 데이터가 아닌 값은 `read`로 읽지 않습니다.
        XCTAssertNil(sut.read("userId"))
    }
}
