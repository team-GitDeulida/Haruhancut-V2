//
//  UserDefaultsStorageTests.swift
//  CoreTests
//
//  Created by 김동현 on 10/10/26.
//

import XCTest
@testable import Core

final class UserDefaultsStorageTests: XCTestCase {

    private struct Profile: Codable, Equatable {
        var id: String
        var createdAt: Date
    }

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

    func test_writeData_storesItAsIs_andOverwrites() throws {
        try sut.write(Data("old".utf8), to: "session.user")
        try sut.write(Data("new".utf8), to: "session.user")

        XCTAssertEqual(defaults.data(forKey: "session.user"), Data("new".utf8))
        XCTAssertEqual(sut.read("session.user"), Data("new".utf8))
        XCTAssertNil(sut.read("missing") as Data?)
    }

    func test_writeModel_storesJSON_andReadDecodesIt() throws {
        let profile = Profile(id: "1", createdAt: Date(timeIntervalSince1970: 0))

        try sut.write(profile, to: "session.user")

        // 기존 세션과 같은 형식(기본 JSONEncoder로 만든 Data)으로 저장합니다
        let stored = try XCTUnwrap(defaults.data(forKey: "session.user"))
        XCTAssertEqual(try JSONDecoder().decode(Profile.self, from: stored), profile)
        XCTAssertEqual(sut.read("session.user"), profile)
        XCTAssertNil(sut.read("session.user") as [String]?)
    }

    func test_remove_deletesValue_andIgnoresMissingKey() throws {
        try sut.write(Data("user".utf8), to: "session.user")

        sut.remove("session.user")
        sut.remove("missing")

        XCTAssertNil(sut.read("session.user") as Data?)
        XCTAssertNil(defaults.object(forKey: "session.user"))
    }
}
