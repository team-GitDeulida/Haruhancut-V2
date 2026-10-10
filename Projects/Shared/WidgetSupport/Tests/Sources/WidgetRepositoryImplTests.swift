//
//  WidgetRepositoryImplTests.swift
//  WidgetSupportTests
//
//  Created by 김동현 on 10/10/26.
//

import Core
import Domain
import UIKit
import XCTest
@testable import WidgetSupport

final class WidgetRepositoryImplTests: XCTestCase {

    private var baseURL: URL!
    private var storage: FileStorage!
    private var now: Date!
    private var sut: WidgetRepositoryImpl!

    override func setUp() {
        super.setUp()
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("WidgetRepositoryImplTests-\(UUID().uuidString)")
        storage = FileStorage(baseURL: baseURL)
        now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        sut = WidgetRepositoryImpl(
            photoStore: WidgetPhotoStore(storage: storage, now: { [unowned self] in self.now }),
            sessionStore: WidgetSessionStore(storage: storage)
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_savePhoto_isFoundByAnyTimeOfThatDay() throws {
        try sut.savePhoto(makeImageData(), groupId: "family", identifier: "photo")

        let startOfDay = Calendar.current.startOfDay(for: now)
        XCTAssertEqual(sut.photoIdentifiers(groupId: "family", date: startOfDay), ["photo"])
        XCTAssertEqual(
            sut.photoIdentifiers(groupId: "family", date: startOfDay.addingTimeInterval(-1)),
            []
        )
    }

    func test_deletePhoto_removesPhotoInDateFolder() throws {
        try sut.savePhoto(makeImageData(), groupId: "family", identifier: "photo")

        sut.deletePhoto(groupId: "family", date: now.addingTimeInterval(3600), identifier: "photo")

        XCTAssertEqual(sut.photoIdentifiers(groupId: "family", date: now), [])
    }

    func test_saveUser_writesUserReadByWidget() {
        sut.saveUser(
            User(
                uid: "user",
                registerDate: now,
                loginPlatform: .kakao,
                nickname: "동현",
                birthdayDate: now,
                gender: .other,
                isPushEnabled: true,
                groupId: "family"
            )
        )

        XCTAssertEqual(WidgetSessionStore(storage: storage).loadUser()?.groupId, "family")
    }

    private func makeImageData() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
            .jpegData(withCompressionQuality: 1) { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }
    }
}
