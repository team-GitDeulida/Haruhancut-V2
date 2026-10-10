//
//  FileStorageTests.swift
//  CoreTests
//
//  Created by 김동현 on 10/10/26.
//

import XCTest
@testable import Core

final class FileStorageTests: XCTestCase {

    private struct Profile: Codable, Equatable {
        var id: String
        var createdAt: Date
    }

    private var baseURL: URL!
    private var sut: FileStorage!

    override func setUp() {
        super.setUp()
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileStorageTests-\(UUID().uuidString)")
        sut = FileStorage(baseURL: baseURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_write_createsIntermediateDirectories_andReadReturnsData() throws {
        let data = Data("photo".utf8)

        try sut.write(data, to: "Photos/family/2026-10-10/photo.jpg")

        XCTAssertEqual(sut.read("Photos/family/2026-10-10/photo.jpg"), data)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: baseURL.appendingPathComponent("Photos/family/2026-10-10/photo.jpg").path
            )
        )
    }

    func test_write_overwritesExistingFile() throws {
        try sut.write(Data("old".utf8), to: "Session/user.json")
        try sut.write(Data("new".utf8), to: "Session/user.json")

        XCTAssertEqual(sut.read("Session/user.json"), Data("new".utf8))
    }

    func test_read_returnsNil_whenFileIsMissing() {
        XCTAssertNil(sut.read("missing.json") as Data?)
    }

    func test_writeModel_storesJSON_andReadDecodesIt() throws {
        let profile = Profile(id: "1", createdAt: Date(timeIntervalSince1970: 0))

        try sut.write(profile, to: "Session/profile.json")

        // 파일에는 기본 JSONDecoder로 읽을 수 있는 JSON이 저장됩니다
        let stored = try XCTUnwrap(sut.read("Session/profile.json") as Data?)
        XCTAssertEqual(try JSONDecoder().decode(Profile.self, from: stored), profile)
        XCTAssertEqual(sut.read("Session/profile.json"), profile)
        XCTAssertNil(sut.read("Session/profile.json") as [String]?)
    }

    func test_contentsOfDirectory_returnsNames_withoutHiddenFiles() throws {
        try sut.write(Data(), to: "Photos/a.jpg")
        try sut.write(Data(), to: "Photos/b.jpg")
        try sut.write(Data(), to: "Photos/.hidden")

        XCTAssertEqual(sut.contentsOfDirectory("Photos").sorted(), ["a.jpg", "b.jpg"])
    }

    func test_contentsOfDirectory_returnsEmpty_whenDirectoryIsMissing() {
        XCTAssertEqual(sut.contentsOfDirectory("Photos/missing"), [])
    }

    func test_remove_deletesFileAndDirectory() throws {
        try sut.write(Data(), to: "Photos/family/a.jpg")
        try sut.write(Data(), to: "Photos/family/b.jpg")

        sut.remove("Photos/family/a.jpg")
        XCTAssertFalse(sut.exists("Photos/family/a.jpg"))
        XCTAssertTrue(sut.exists("Photos/family/b.jpg"))

        sut.remove("Photos/family")
        XCTAssertFalse(sut.exists("Photos/family"))
    }

    func test_remove_ignoresMissingPath() {
        sut.remove("Photos/missing")

        XCTAssertFalse(sut.exists("Photos/missing"))
    }

    func test_pathEscapingBaseFolder_isRejected() throws {
        let outside = baseURL.deletingLastPathComponent()
            .appendingPathComponent("FileStorageTests-outside-\(UUID().uuidString).txt")
        try Data("outside".utf8).write(to: outside)
        defer { try? FileManager.default.removeItem(at: outside) }
        let escapingPath = "../" + outside.lastPathComponent

        XCTAssertThrowsError(try sut.write(Data("changed".utf8), to: escapingPath))
        XCTAssertNil(sut.read(escapingPath) as Data?)
        XCTAssertFalse(sut.exists(escapingPath))
        XCTAssertEqual(sut.contentsOfDirectory(".."), [])
        sut.remove(escapingPath)

        XCTAssertEqual(try Data(contentsOf: outside), Data("outside".utf8))
    }

    func test_emptyPath_doesNotTouchBaseFolder() throws {
        try sut.write(Data("keep".utf8), to: "Photos/keep.jpg")

        for path in ["", "/", "//"] {
            XCTAssertThrowsError(try sut.write(Data(), to: path))
            XCTAssertNil(sut.read(path) as Data?)
            XCTAssertFalse(sut.exists(path))
            XCTAssertEqual(sut.contentsOfDirectory(path), [])
            sut.remove(path)
        }

        XCTAssertEqual(sut.read("Photos/keep.jpg"), Data("keep".utf8))
    }

    func test_locationInit_findsSandboxDirectories() {
        // App Group은 시뮬레이터가 권한 없이도 경로를 돌려줄 수 있어 검사하지 않습니다.
        XCTAssertNotNil(FileStorage(location: .documents))
        XCTAssertNotNil(FileStorage(location: .caches))
    }
}
