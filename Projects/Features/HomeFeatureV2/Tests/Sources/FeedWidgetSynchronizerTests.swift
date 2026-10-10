@testable import HomeFeatureV2
import Domain
import XCTest

final class FeedWidgetSynchronizerTests: XCTestCase {
    private let groupID = "group"
    private var store: FakeFeedWidgetStore!
    private var loader: FakeImageDataLoader!
    private var sut: FeedWidgetSynchronizer!

    override func setUp() {
        super.setUp()
        store = FakeFeedWidgetStore()
        loader = FakeImageDataLoader()
        sut = FeedWidgetSynchronizer(
            store: store,
            loadImageData: loader.load,
            workQueue: DispatchQueue(label: "FeedWidgetSynchronizerTests")
        )
    }

    func testSynchronizeSavesUserAndLatestTodayPhoto() {
        let latest = makePost(id: "latest", minutes: 2)

        synchronize([
            makePost(id: "yesterday", createdAt: yesterday()),
            makePost(id: "older", minutes: 1),
            latest,
        ])
        XCTAssertEqual(store.savedUserIDs, ["user"])
        XCTAssertEqual(loader.requestedURLs, [URL(string: latest.imageURL)!])

        completeDownloads()

        XCTAssertEqual(store.todayIdentifiers, ["latest"])
        XCTAssertEqual(store.reloadCount, 1)
    }

    func testSynchronizeSkipsDownloadWhenPhotoIsAlreadySaved() {
        store.todayIdentifiers = ["latest"]

        synchronize([makePost(id: "latest", minutes: 2)])

        XCTAssertTrue(loader.requestedURLs.isEmpty)
        XCTAssertEqual(store.todayIdentifiers, ["latest"])
        XCTAssertEqual(store.reloadCount, 0)
    }

    func testSynchronizeReplacesOutdatedPhotoAfterNewPhotoIsSaved() {
        store.todayIdentifiers = ["older"]

        synchronize([makePost(id: "older", minutes: 1), makePost(id: "latest", minutes: 2)])
        // 새 사진을 저장하기 전까지 기존 사진을 유지합니다.
        XCTAssertEqual(store.todayIdentifiers, ["older"])

        completeDownloads()

        XCTAssertEqual(store.todayIdentifiers, ["latest"])
        XCTAssertEqual(store.reloadCount, 1)
    }

    func testStaleCachedPostIsNotSavedAfterServerResult() {
        store.todayIdentifiers = ["server-latest"]

        // 캐시에는 다른 기기에서 지운 게시물이 최신으로 남아 있습니다.
        synchronize([makePost(id: "deleted-elsewhere", minutes: 3)])
        // 서버 결과에는 이미 저장된 게시물이 최신입니다.
        synchronize([makePost(id: "server-latest", minutes: 2)])
        completeDownloads()

        XCTAssertEqual(store.todayIdentifiers, ["server-latest"])
    }

    func testPhotoDeletedDuringDownloadIsNotSaved() {
        let post = makePost(id: "deleted", minutes: 2)

        synchronize([post])
        sut.removePhoto(of: post, user: makeWidgetTestUser(groupID: groupID))
        synchronize([])
        completeDownloads()

        XCTAssertTrue(store.todayIdentifiers.isEmpty)
    }

    func testDownloadFinishedAfterMidnightIsNotSaved() {
        var current = Calendar.current.startOfDay(for: .now)
            .addingTimeInterval(23 * 3600 + 59 * 60 + 50)
        let sut = FeedWidgetSynchronizer(
            store: store,
            loadImageData: loader.load,
            workQueue: DispatchQueue(label: "FeedWidgetSynchronizerTests.midnight"),
            now: { current }
        )
        let post = makePost(id: "late-night", createdAt: current.addingTimeInterval(-5))

        sut.synchronize(
            user: makeWidgetTestUser(groupID: groupID),
            postsByDate: ["posts": [post]]
        )
        sut.waitUntilIdle()
        XCTAssertEqual(loader.requestedURLs.count, 1)

        // 다운로드가 자정을 넘겨 끝납니다.
        current = current.addingTimeInterval(15)
        loader.completeAll(with: Data([0x01]))
        sut.waitUntilIdle()

        XCTAssertTrue(store.todayIdentifiers.isEmpty)
    }

    func testSynchronizeDoesNotDownloadSamePostTwiceWhileLoading() {
        let latest = makePost(id: "latest", minutes: 2)

        synchronize([latest])
        synchronize([latest])

        XCTAssertEqual(loader.requestedURLs.count, 1)
    }

    func testSynchronizeRemovesTodayPhotosWhenThereIsNoTodayPost() {
        store.todayIdentifiers = ["deleted-elsewhere"]

        synchronize([makePost(id: "yesterday", createdAt: yesterday())])

        XCTAssertEqual(store.savedUserIDs, ["user"])
        XCTAssertTrue(loader.requestedURLs.isEmpty)
        XCTAssertTrue(store.todayIdentifiers.isEmpty)
        XCTAssertEqual(store.reloadCount, 1)
    }

    func testSynchronizeDoesNothingWithoutGroup() {
        sut.synchronize(
            user: makeWidgetTestUser(groupID: nil),
            postsByDate: ["today": [makePost(id: "latest", minutes: 2)]]
        )
        sut.waitUntilIdle()

        XCTAssertTrue(store.savedUserIDs.isEmpty)
        XCTAssertTrue(loader.requestedURLs.isEmpty)
    }

    func testSynchronizeDoesNotSaveWhenDownloadFails() {
        synchronize([makePost(id: "latest", minutes: 2)])
        completeDownloads(with: nil)

        XCTAssertTrue(store.todayIdentifiers.isEmpty)
        XCTAssertEqual(store.reloadCount, 0)
    }

    func testRemovePhotoDeletesPostPhotoAndReloadsWidget() {
        store.todayIdentifiers = ["deleted"]

        sut.removePhoto(
            of: makePost(id: "deleted", minutes: 1),
            user: makeWidgetTestUser(groupID: groupID)
        )
        sut.waitUntilIdle()

        XCTAssertTrue(store.todayIdentifiers.isEmpty)
        XCTAssertEqual(store.reloadCount, 1)
    }

    func testOnlyCurrentGroupSynchronizesWidget() {
        XCTAssertNotNil(FeedWidgetSynchronizer.make(for: .currentGroup))
        XCTAssertNil(FeedWidgetSynchronizer.make(for: .adminPreview(groupID: "other-group")))
    }

    private func synchronize(_ posts: [Post]) {
        sut.synchronize(
            user: makeWidgetTestUser(groupID: groupID),
            postsByDate: ["posts": posts]
        )
        sut.waitUntilIdle()
    }

    private func completeDownloads(with data: Data? = Data([0x01])) {
        loader.completeAll(with: data)
        sut.waitUntilIdle()
    }

    private func makePost(id: String, minutes: Int) -> Post {
        makePost(
            id: id,
            createdAt: Calendar.current.startOfDay(for: .now)
                .addingTimeInterval(TimeInterval(minutes * 60))
        )
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

/// 오늘 날짜 폴더 하나만 흉내 내는 위젯 저장소입니다.
private final class FakeFeedWidgetStore: FeedWidgetStoring {
    /// 오늘 폴더에 저장된 사진의 식별자입니다.
    var todayIdentifiers: [String] = []
    private(set) var savedUserIDs: [String] = []
    private(set) var reloadCount = 0

    func saveUser(_ user: User) {
        savedUserIDs.append(user.uid)
    }

    func photoIdentifiers(groupId _: String, dateKey: String) -> [String] {
        dateKey == todayKey ? todayIdentifiers : []
    }

    func savePhoto(data _: Data, groupId _: String, identifier: String) throws {
        todayIdentifiers.append(identifier)
    }

    func deletePhoto(groupId _: String, dateKey: String, identifier: String) {
        guard dateKey == todayKey else { return }
        todayIdentifiers.removeAll { $0 == identifier }
    }

    func reloadWidget() {
        reloadCount += 1
    }

    private var todayKey: String {
        FeedWidgetSynchronizer.dateKey(
            of: Post(
                postId: "today",
                userId: "user",
                nickname: "user",
                profileImageURL: nil,
                imageURL: "",
                createdAt: .now,
                likeCount: 0,
                comments: [:]
            )
        )
    }
}

/// 다운로드 완료 시점을 테스트가 정하는 이미지 로더입니다.
private final class FakeImageDataLoader {
    private(set) var requestedURLs: [URL] = []
    private var completions: [(Data?) -> Void] = []

    func load(url: URL, completion: @escaping (Data?) -> Void) {
        requestedURLs.append(url)
        completions.append(completion)
    }

    func completeAll(with data: Data?) {
        let pending = completions
        completions.removeAll()
        pending.forEach { $0(data) }
    }
}
