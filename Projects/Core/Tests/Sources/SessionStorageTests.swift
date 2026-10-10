//
//  SessionStorageTests.swift
//  CoreTests
//
//  Created by 김동현 on 10/10/26.
//

import XCTest
@testable import Core

/// `SessionContext`가 공통 저장소 계약(`StorageType`)만으로 동작하는지 확인합니다.
final class SessionStorageTests: XCTestCase {

    private struct Profile: Codable, Equatable, CustomStringConvertible {
        var id: String
        var description: String { "Profile(id: \(id))" }
    }

    private var baseURL: URL!

    override func setUp() {
        super.setUp()
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SessionStorageTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_session_persistsRestoresAndClears_withFileStorage() {
        let storage = FileStorage(baseURL: baseURL)
        let session = SessionContext<Profile>(storage: storage, storageKey: "Session/profile.json")

        session.update(Profile(id: "1"))
        XCTAssertTrue(storage.exists("Session/profile.json"))

        let restored = SessionContext<Profile>(storage: storage, storageKey: "Session/profile.json")
        XCTAssertEqual(restored.session, Profile(id: "1"))

        restored.clear()
        XCTAssertFalse(storage.exists("Session/profile.json"))
    }

    func test_session_persistsAndRestores_withUserDefaultsStorageProtocolFake() {
        let storage = FakeUserDefaultsStorage()
        SessionContext<Profile>(storage: storage, storageKey: "profile").update(Profile(id: "1"))

        XCTAssertNotNil(storage.read("profile"))
        XCTAssertEqual(
            SessionContext<Profile>(storage: storage, storageKey: "profile").session,
            Profile(id: "1")
        )
    }
}
