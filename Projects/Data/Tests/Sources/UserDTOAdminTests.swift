import Domain
import Foundation
@testable import Data
import XCTest

final class UserDTOAdminTests:
    XCTestCase
{
    func testLegacyUserWithoutAdminFieldDecodesAsNil() throws {
        let json =
            """
            {
              "uid": "legacy-user",
              "registerDate": "2026-01-01T00:00:00Z",
              "loginPlatform": "apple",
              "nickname": "기존 사용자",
              "birthdayDate": "2000-01-01T00:00:00Z",
              "gender": "비공개",
              "isPushEnabled": true,
              "groupId": "group"
            }
            """
            .data(using: .utf8)!

        let dto = try JSONDecoder()
            .decode(
                UserDTO.self,
                from: json
            )

        XCTAssertNil(dto.isAdmin)
        XCTAssertNil(
            dto.toModel()?.isAdmin
        )
    }

    func testAdminFieldSurvivesEntityDTORoundTrip() {
        let user =
            User(
                uid: "admin",
                registerDate: .now,
                loginPlatform: .apple,
                nickname: "관리자",
                birthdayDate: .now,
                gender: .other,
                isPushEnabled: true,
                groupId: "group",
                isAdmin: true
            )

        let converted =
            user.toDTO().toModel()

        XCTAssertEqual(
            converted?.isAdmin,
            true
        )
    }
}
