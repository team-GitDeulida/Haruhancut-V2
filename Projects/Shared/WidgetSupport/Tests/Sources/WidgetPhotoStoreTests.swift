//
//  WidgetPhotoStoreTests.swift
//  WidgetSupportTests
//
//  Created by 김동현 on 10/10/26.
//

import Core
import UIKit
import XCTest
@testable import WidgetSupport

final class WidgetPhotoStoreTests: XCTestCase {

    private var baseURL: URL!
    private var storage: FileStorage!
    private var now: Date!
    private var sut: WidgetPhotoStore!

    override func setUp() {
        super.setUp()
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("WidgetPhotoStoreTests-\(UUID().uuidString)")
        storage = FileStorage(baseURL: baseURL)
        now = makeDate(hour: 12, minute: 30, second: 10)
        sut = WidgetPhotoStore(storage: storage, now: { [unowned self] in self.now })
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_saveImage_keepsExistingPathAndFileNameFormat() throws {
        try sut.saveImage(data: makeImageData(), groupId: "family", identifier: "photo1")

        let dateKey = now.widgetDateKey()
        XCTAssertEqual(
            storage.contentsOfDirectory("Photos/family/\(dateKey)"),
            ["\(now.widgetTimestamp())-photo1.jpg"]
        )
    }

    func test_photoIdentifiers_readsIdentifiersContainingHyphens() throws {
        let identifiers = ["-OmtewEFRElL3TAKUDMB", "DC9AEE45-0D81-474A-A55E-FBBD1B3FEFCB"]
        for identifier in identifiers {
            try sut.saveImage(data: makeImageData(), groupId: "family", identifier: identifier)
            now = now.addingTimeInterval(1)
        }

        XCTAssertEqual(
            sut.photoIdentifiers(groupId: "family", dateKey: now.widgetDateKey()),
            identifiers
        )
    }

    func test_latestPhotoData_returnsLastSavedPhoto() throws {
        try sut.saveImage(data: makeImageData(color: .red), groupId: "family", identifier: "old")
        now = now.addingTimeInterval(1)
        try sut.saveImage(data: makeImageData(color: .blue), groupId: "family", identifier: "new")

        let dateKey = now.widgetDateKey()
        let latestPath = "Photos/family/\(dateKey)/\(now.widgetTimestamp())-new.jpg"
        XCTAssertEqual(sut.latestPhotoData(groupId: "family", dateKey: dateKey), storage.read(latestPath))
        XCTAssertNil(sut.latestPhotoData(groupId: "family", dateKey: "2000-01-01"))
    }

    func test_latestPhotoData_withoutDate_readsLatestDateFolder() throws {
        try sut.saveImage(data: makeImageData(), groupId: "family", identifier: "yesterday")
        now = now.addingTimeInterval(24 * 60 * 60)
        try sut.saveImage(data: makeImageData(), groupId: "family", identifier: "today")

        let todayPath = "Photos/family/\(now.widgetDateKey())/\(now.widgetTimestamp())-today.jpg"
        XCTAssertEqual(sut.latestPhotoData(groupId: "family"), storage.read(todayPath))
    }

    func test_deleteImage_removesPhoto_andEmptyDateFolder() throws {
        try sut.saveImage(data: makeImageData(), groupId: "family", identifier: "keep")
        now = now.addingTimeInterval(1)
        try sut.saveImage(data: makeImageData(), groupId: "family", identifier: "delete")
        let dateKey = now.widgetDateKey()

        sut.deleteImage(groupId: "family", dateKey: dateKey, identifier: "delete")
        XCTAssertEqual(sut.photoIdentifiers(groupId: "family", dateKey: dateKey), ["keep"])

        sut.deleteImage(groupId: "family", dateKey: dateKey, identifier: "keep")
        XCTAssertFalse(storage.exists("Photos/family/\(dateKey)"))
    }

    func test_saveImage_throwsInvalidPath_withoutStorage() {
        let sut = WidgetPhotoStore(storage: nil)

        XCTAssertThrowsError(
            try sut.saveImage(data: makeImageData(), groupId: "family", identifier: "photo")
        ) { error in
            XCTAssertEqual(error as? WidgetPhotoError, .invalidPath)
        }
    }

    func test_saveImage_throwsInvalidImage_forNonImageData() {
        XCTAssertThrowsError(
            try sut.saveImage(data: Data("not an image".utf8), groupId: "family", identifier: "photo")
        ) { error in
            XCTAssertEqual(error as? WidgetPhotoError, .invalidImage)
        }
        XCTAssertFalse(storage.exists("Photos/family"))
    }

    private func makeDate(hour: Int, minute: Int, second: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: second,
            of: Date()
        )!
    }

    private func makeImageData(color: UIColor = .red) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
            .jpegData(withCompressionQuality: 1) { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }
    }
}
