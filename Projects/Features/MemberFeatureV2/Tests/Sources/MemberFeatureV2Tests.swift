import Domain
import XCTest
@testable import MemberFeatureV2

final class MemberFeatureV2Tests:
    XCTestCase
{
    func testHeaderComponentUsesMemberCount() {
        let component =
            MemberHeaderComponent(
                memberCount: 3
            )

        XCTAssertEqual(
            component.item.id,
            "member-count-header"
        )
        XCTAssertEqual(
            component.item.memberCount,
            3
        )
    }

    func testInviteComponentUsesStableIdentifier() {
        let component =
            MemberRowComponent.invite

        XCTAssertEqual(
            component.item.id,
            .invite
        )
        XCTAssertEqual(
            component.item.content,
            .invite
        )
    }

    func testMemberComponentUsesUserValues() {
        let user = makeUser()
        let component =
            MemberRowComponent(
                user: user
            )

        XCTAssertEqual(
            component.item.id,
            .member(user.uid)
        )
        XCTAssertEqual(
            component.item.content,
            .member(
                nickname: user.nickname,
                profileImageURL:
                    user.profileImageURL
            )
        )
    }

    private func makeUser() -> User {
        User(
            uid: "member-id",
            registerDate:
                Date(
                    timeIntervalSince1970:
                        1_700_000_000
                ),
            loginPlatform: .apple,
            nickname: "하루",
            profileImageURL:
                "https://example.com/member.jpg",
            birthdayDate:
                Date(
                    timeIntervalSince1970:
                        946_684_800
                ),
            gender: .other,
            isPushEnabled: true
        )
    }
}
