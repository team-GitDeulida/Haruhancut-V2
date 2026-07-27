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

    func testBirthdayIsNormalizedToStartOfDay() {
        var calendar =
            Calendar(
                identifier: .gregorian
            )
        calendar.timeZone =
            TimeZone(
                secondsFromGMT: 0
            )!
        let birthday =
            calendar.date(
                from:
                    DateComponents(
                        year: 2000,
                        month: 11,
                        day: 11,
                        hour: 18,
                        minute: 30
                    )
            )!

        let normalized =
            BirthdayEditViewModel
                .normalizedBirthday(
                    birthday,
                    calendar: calendar
                )

        XCTAssertEqual(
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                ],
                from: normalized
            ),
            DateComponents(
                year: 2000,
                month: 11,
                day: 11,
                hour: 0,
                minute: 0
            )
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
