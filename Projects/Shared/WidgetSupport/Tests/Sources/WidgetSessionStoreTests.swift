//
//  WidgetSessionStoreTests.swift
//  WidgetSupportTests
//
//  Created by 김동현 on 10/10/26.
//

import Core
import Domain
import XCTest
@testable import WidgetSupport

final class WidgetSessionStoreTests: XCTestCase {

    private var baseURL: URL!
    private var storage: FileStorage!

    override func setUp() {
        super.setUp()
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("WidgetSessionStoreTests-\(UUID().uuidString)")
        storage = FileStorage(baseURL: baseURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_saveUser_writesSessionFile_andLoadUserReadsIt() {
        let sut = WidgetSessionStore(storage: storage)
        let user = User(
            uid: "user",
            registerDate: Date(timeIntervalSince1970: 0),
            loginPlatform: .kakao,
            nickname: "동현",
            birthdayDate: Date(timeIntervalSince1970: 0),
            gender: .other,
            isPushEnabled: true,
            groupId: "family"
        )

        sut.saveUser(user)

        XCTAssertTrue(storage.exists("Session/user.json"))
        XCTAssertEqual(sut.loadUser()?.uid, "user")
        XCTAssertEqual(sut.loadUser()?.groupId, "family")
    }

    func test_loadUser_returnsNil_whenNothingIsSaved() {
        XCTAssertNil(WidgetSessionStore(storage: storage).loadUser())
        XCTAssertNil(WidgetSessionStore(storage: nil).loadUser())
    }
}
