import Foundation
import RxSwift
import XCTest
@testable import Data

/// Realtime Database 읽기 결과를 값·없음·실패로 나누는지 확인합니다.
final class FirebaseReadTests: XCTestCase {
    private struct Profile: Decodable, Equatable {
        let name: String
    }

    private enum TestError: Error {
        case remote
    }

    // MARK: - decode

    func testDecodeThrowsPathNotFoundWhenSnapshotIsNull() {
        XCTAssertThrowsError(
            try FirebaseAuthManager.decode(Profile.self, from: NSNull())
        ) { error in
            XCTAssertTrue(isPathNotFound(error))
        }
    }

    func testDecodeThrowsPathNotFoundWhenValueIsMissing() {
        XCTAssertThrowsError(
            try FirebaseAuthManager.decode(Profile.self, from: nil)
        ) { error in
            XCTAssertTrue(isPathNotFound(error))
        }
    }

    func testDecodeReturnsModelFromDictionary() throws {
        let profile = try FirebaseAuthManager.decode(
            Profile.self,
            from: ["name": "하루"]
        )

        XCTAssertEqual(profile, Profile(name: "하루"))
    }

    func testDecodeThrowsDecodingFailedWhenFieldsDoNotMatch() {
        XCTAssertThrowsError(
            try FirebaseAuthManager.decode(Profile.self, from: ["nickname": "하루"])
        ) { error in
            XCTAssertTrue(isDecodingFailed(error))
        }
    }

    func testDecodeThrowsDecodingFailedWhenValueIsNotJSONObject() {
        XCTAssertThrowsError(
            try FirebaseAuthManager.decode(Profile.self, from: "하루")
        ) { error in
            XCTAssertTrue(isDecodingFailed(error))
        }
    }

    // MARK: - nilIfPathNotFound

    func testNilIfPathNotFoundKeepsValue() async throws {
        let value = try await Single.just(1)
            .nilIfPathNotFound()
            .value

        XCTAssertEqual(value, 1)
    }

    func testNilIfPathNotFoundReturnsNilForMissingPath() async throws {
        let value = try await Single<Int>.error(FirebaseError.pathNotFound)
            .nilIfPathNotFound()
            .value

        XCTAssertNil(value)
    }

    func testNilIfPathNotFoundKeepsOtherErrors() async {
        do {
            _ = try await Single<Int>.error(TestError.remote)
                .nilIfPathNotFound()
                .value
            XCTFail("경로 없음이 아닌 에러는 그대로 보내야 합니다.")
        } catch TestError.remote {
        } catch {
            XCTFail("예상하지 못한 오류입니다: \(error)")
        }
    }
}

private extension FirebaseReadTests {
    func isPathNotFound(_ error: Error) -> Bool {
        if case FirebaseError.pathNotFound = error {
            return true
        }
        return false
    }

    func isDecodingFailed(_ error: Error) -> Bool {
        if case FirebaseError.decodingFailed = error {
            return true
        }
        return false
    }
}
