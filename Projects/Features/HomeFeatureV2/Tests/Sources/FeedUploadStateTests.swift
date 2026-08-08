@testable import HomeFeatureV2
import Domain
import XCTest

final class FeedUploadStateTests: XCTestCase {
    private let currentUserID = "current-user"

    func testFamilyPostDoesNotMarkCurrentUserUploadAsComplete() {
        let components = makeComponents(
            posts: [makePost(id: "family-post", userID: "family-user")]
        )

        XCTAssertEqual(components.map(\.post.postId), ["family-post"])
        XCTAssertFalse(
            FeedReactor.didTodayUpload(
                in: components,
                currentUserID: currentUserID
            )
        )
    }

    func testCurrentUserPostMarksUploadAsComplete() {
        let components = makeComponents(
            posts: [makePost(id: "my-post", userID: currentUserID)]
        )

        XCTAssertTrue(
            FeedReactor.didTodayUpload(
                in: components,
                currentUserID: currentUserID
            )
        )
    }

    func testFamilyAndCurrentUserPostsRemainVisibleWithCurrentUserUploadComplete() {
        let components = makeComponents(
            posts: [
                makePost(id: "family-post", userID: "family-user"),
                makePost(id: "my-post", userID: currentUserID),
            ]
        )

        XCTAssertEqual(Set(components.map(\.post.postId)), ["family-post", "my-post"])
        XCTAssertTrue(
            FeedReactor.didTodayUpload(
                in: components,
                currentUserID: currentUserID
            )
        )
    }

    private func makeComponents(posts: [Post]) -> [FeedComponent] {
        FeedReactor.makeComponents(from: ["today": posts])
    }

    private func makePost(id: String, userID: String) -> Post {
        Post(
            postId: id,
            userId: userID,
            nickname: userID,
            profileImageURL: nil,
            imageURL: "https://example.com/\(id).jpg",
            createdAt: .now,
            likeCount: 0,
            comments: [:]
        )
    }
}
