@testable import HomeFeatureV2
import Domain
import XCTest

final class FeedWidgetSynchronizerTests: XCTestCase {
    private let groupID = "group"

    func testSynchronizeSavesUserAndLatestTodayPhoto() {
        let store = FakeFeedWidgetStore()
        let loader = FakeImageDataLoader()
        let sut = makeSUT(store: store, loader: loader)
        let latestPost = makePost(id: "latest", createdAt: todayAt(minutes: 2))

        sut.synchronize(
            user: makeWidgetTestUser(groupID: groupID),
            postsByDate: [
                "yesterday": [makePost(id: "yesterday", createdAt: yesterday())],
                "today": [
                    makePost(id: "older", createdAt: todayAt(minutes: 1)),
                    latestPost,
                ],
            ]
        )

        XCTAssertEqual(store.savedUserIDs, ["user"])
        XCTAssertEqual(loader.requestedURLs, [URL(string: latestPost.imageURL)])
        XCTAssertEqual(store.savedPhotos, [.init(groupId: groupID, identifier: "latest")])
        XCTAssertEqual(store.reloadCount, 1)
    }

    func testSynchronizeSkipsDownloadWhenPhotoIsAlreadySaved() {
        let latestPost = makePost(id: "latest", createdAt: todayAt(minutes: 2))
        let store = FakeFeedWidgetStore()
        store.existingPhotos = [
            .init(
                groupId: groupID,
                dateKey: FeedWidgetSynchronizer.dateKey(of: latestPost),
                identifier: "latest"
            ),
        ]
        let loader = FakeImageDataLoader()
        let sut = makeSUT(store: store, loader: loader)

        sut.synchronize(
            user: makeWidgetTestUser(groupID: groupID),
            postsByDate: ["today": [latestPost]]
        )

        XCTAssertEqual(store.savedUserIDs, ["user"])
        XCTAssertTrue(loader.requestedURLs.isEmpty)
        XCTAssertTrue(store.savedPhotos.isEmpty)
        XCTAssertEqual(store.reloadCount, 0)
    }

    func testSynchronizeSavesOnlyUserWhenThereIsNoTodayPost() {
        let store = FakeFeedWidgetStore()
        let loader = FakeImageDataLoader()
        let sut = makeSUT(store: store, loader: loader)

        sut.synchronize(
            user: makeWidgetTestUser(groupID: groupID),
            postsByDate: ["yesterday": [makePost(id: "yesterday", createdAt: yesterday())]]
        )

        XCTAssertEqual(store.savedUserIDs, ["user"])
        XCTAssertTrue(loader.requestedURLs.isEmpty)
        XCTAssertEqual(store.reloadCount, 0)
    }

    func testSynchronizeDoesNothingWithoutGroup() {
        let store = FakeFeedWidgetStore()
        let loader = FakeImageDataLoader()
        let sut = makeSUT(store: store, loader: loader)

        sut.synchronize(
            user: makeWidgetTestUser(groupID: nil),
            postsByDate: ["today": [makePost(id: "latest", createdAt: todayAt(minutes: 2))]]
        )

        XCTAssertTrue(store.savedUserIDs.isEmpty)
        XCTAssertTrue(loader.requestedURLs.isEmpty)
    }

    func testSynchronizeDoesNotSaveWhenDownloadFails() {
        let store = FakeFeedWidgetStore()
        let loader = FakeImageDataLoader(data: nil)
        let sut = makeSUT(store: store, loader: loader)

        sut.synchronize(
            user: makeWidgetTestUser(groupID: groupID),
            postsByDate: ["today": [makePost(id: "latest", createdAt: todayAt(minutes: 2))]]
        )

        XCTAssertTrue(store.savedPhotos.isEmpty)
        XCTAssertEqual(store.reloadCount, 0)
    }

    func testRemovePhotoDeletesPostPhotoAndReloadsWidget() {
        let store = FakeFeedWidgetStore()
        let sut = makeSUT(store: store, loader: FakeImageDataLoader())
        let post = makePost(id: "deleted", createdAt: todayAt(minutes: 1))

        sut.removePhoto(of: post, user: makeWidgetTestUser(groupID: groupID))

        XCTAssertEqual(
            store.deletedPhotos,
            [
                .init(
                    groupId: groupID,
                    dateKey: FeedWidgetSynchronizer.dateKey(of: post),
                    identifier: "deleted"
                ),
            ]
        )
        XCTAssertEqual(store.reloadCount, 1)
    }

    func testOnlyCurrentGroupSynchronizesWidget() {
        XCTAssertNotNil(FeedWidgetSynchronizer.make(for: .currentGroup))
        XCTAssertNil(FeedWidgetSynchronizer.make(for: .adminPreview(groupID: "other-group")))
    }

    private func makeSUT(
        store: FakeFeedWidgetStore,
        loader: FakeImageDataLoader
    ) -> FeedWidgetSynchronizer {
        FeedWidgetSynchronizer(store: store, loadImageData: loader.load)
    }

    private func todayAt(minutes: Int) -> Date {
        Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(minutes * 60))
    }

    private func yesterday() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: .now)!
    }

    private func makePost(id: String, createdAt: Date) -> Post {
        Post(
            postId: id,
            userId: "user",
            nickname: "user",
            profileImageURL: nil,
            imageURL: "https://example.com/\(id).jpg",
            createdAt: createdAt,
            likeCount: 0,
            comments: [:]
        )
    }
}

func makeWidgetTestUser(groupID: String?) -> User {
    User(
        uid: "user",
        registerDate: .now,
        loginPlatform: .kakao,
        nickname: "user",
        birthdayDate: .now,
        gender: .other,
        isPushEnabled: true,
        groupId: groupID
    )
}

private final class FakeFeedWidgetStore: FeedWidgetStoring {
    struct Photo: Equatable {
        var groupId: String
        var dateKey: String? = nil
        var identifier: String
    }

    var existingPhotos: [Photo] = []
    private(set) var savedUserIDs: [String] = []
    private(set) var savedPhotos: [Photo] = []
    private(set) var deletedPhotos: [Photo] = []
    private(set) var reloadCount = 0

    func saveUser(_ user: User) {
        savedUserIDs.append(user.uid)
    }

    func hasPhoto(groupId: String, dateKey: String, identifier: String) -> Bool {
        existingPhotos.contains(Photo(groupId: groupId, dateKey: dateKey, identifier: identifier))
    }

    func savePhoto(data _: Data, groupId: String, identifier: String) throws {
        savedPhotos.append(Photo(groupId: groupId, identifier: identifier))
    }

    func deletePhoto(groupId: String, dateKey: String, identifier: String) {
        deletedPhotos.append(Photo(groupId: groupId, dateKey: dateKey, identifier: identifier))
    }

    func reloadWidget() {
        reloadCount += 1
    }
}

private final class FakeImageDataLoader {
    private let data: Data?
    private(set) var requestedURLs: [URL?] = []

    init(data: Data? = Data([0x01])) {
        self.data = data
    }

    func load(url: URL, completion: @escaping (Data?) -> Void) {
        requestedURLs.append(url)
        completion(data)
    }
}
