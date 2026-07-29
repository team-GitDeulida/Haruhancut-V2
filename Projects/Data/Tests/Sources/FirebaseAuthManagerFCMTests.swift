import Foundation
import XCTest
@testable import Data

final class FirebaseAuthManagerFCMTests: XCTestCase {
    func testGenerateFcmTokenFailsBeforeAPNsRegistration() async {
        var fcmTokenRequestCount = 0
        let sut = FirebaseAuthManager(
            apnsTokenProvider: { nil },
            fcmTokenProvider: { completion in
                fcmTokenRequestCount += 1
                completion("fcm-token", nil)
            }
        )

        do {
            _ = try await sut.generateFcmToken().value
            XCTFail("APNs token이 없으면 FCM token을 반환하면 안 됩니다.")
        } catch FirebaseError.noAPNSToken {
            XCTAssertEqual(fcmTokenRequestCount, 0)
        } catch {
            XCTFail("예상하지 못한 오류입니다: \(error)")
        }
    }

    func testGenerateFcmTokenSucceedsAfterAPNsRegistration() async throws {
        let sut = FirebaseAuthManager(
            apnsTokenProvider: { Data([0x01]) },
            fcmTokenProvider: { completion in
                completion("fcm-token", nil)
            }
        )

        let token = try await sut.generateFcmToken().value

        XCTAssertEqual(token, "fcm-token")
    }
}
