import Domain
import XCTest
@testable import ProfileFeatureV2

final class ProfileFeatureV2Tests:
    XCTestCase
{
    func testProfilePostComponentUsesPostID() {
        let post = makePost(
            id: "post-id"
        )

        let component =
            ProfilePostComponent(
                post: post
            )

        XCTAssertEqual(
            component.item.id,
            post.postId
        )
        XCTAssertEqual(
            component.item.imageURL,
            post.imageURL
        )
    }

    func testSettingRowIdentifiersAreStable() {
        let first =
            SettingRowContentView.Item(
                id: .notification,
                title: "알림",
                accessory: .toggle(true),
                role: .normal
            )
        let updated =
            SettingRowContentView.Item(
                id: .notification,
                title: "알림",
                accessory: .toggle(false),
                role: .normal
            )

        XCTAssertEqual(
            first.id,
            updated.id
        )
        XCTAssertNotEqual(
            first,
            updated
        )
    }

    private func makePost(
        id: String
    ) -> Post {
        Post(
            postId: id,
            userId: "user",
            nickname: "하루",
            profileImageURL: nil,
            imageURL:
                "https://example.com/\(id).jpg",
            createdAt: .now,
            likeCount: 0,
            comments: [:]
        )
    }
}
