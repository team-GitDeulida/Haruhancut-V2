import Core
import RxSwift
import XCTest
@testable import Domain

final class WidgetUsecaseTests: XCTestCase {
    private let groupId = "group"
    private var repository: FakeWidgetRepository!
    private var userSession: UserSession!
    private var sut: WidgetUsecaseImpl!

    override func setUp() {
        super.setUp()
        repository = FakeWidgetRepository()
        userSession = UserSession(
            storage: InMemoryStorage(),
            storageKey: "WidgetUsecaseTests.user"
        )
        userSession.update(makeUser(groupId: groupId))
        sut = makeSUT()
    }

    func testSynchronizeSavesUserAndLatestTodayPhoto() {
        let latest = makePost(id: "latest", minutes: 2)

        synchronize([
            makePost(id: "yesterday", createdAt: yesterday()),
            makePost(id: "older", minutes: 1),
            latest,
        ])
        XCTAssertEqual(repository.savedUserIds, ["user"])
        XCTAssertEqual(repository.requestedURLs, [URL(string: latest.imageURL)!])

        completeDownloads()

        XCTAssertEqual(repository.todayIdentifiers, ["latest"])
        XCTAssertEqual(repository.reloadCount, 1)
    }

    func testSynchronizeSkipsDownloadWhenPhotoIsAlreadySaved() {
        repository.todayIdentifiers = ["latest"]

        synchronize([makePost(id: "latest", minutes: 2)])

        XCTAssertTrue(repository.requestedURLs.isEmpty)
        XCTAssertEqual(repository.todayIdentifiers, ["latest"])
        XCTAssertEqual(repository.reloadCount, 0)
    }

    func testSynchronizeReplacesOutdatedPhotoAfterNewPhotoIsSaved() {
        repository.todayIdentifiers = ["older"]

        synchronize([makePost(id: "older", minutes: 1), makePost(id: "latest", minutes: 2)])
        // 새 사진을 저장하기 전까지 기존 사진을 유지합니다.
        XCTAssertEqual(repository.todayIdentifiers, ["older"])

        completeDownloads()

        XCTAssertEqual(repository.todayIdentifiers, ["latest"])
        XCTAssertEqual(repository.reloadCount, 1)
    }

    func testStaleCachedPostIsNotSavedAfterServerResult() {
        repository.todayIdentifiers = ["server-latest"]

        // 캐시에는 다른 기기에서 지운 게시물이 최신으로 남아 있습니다.
        synchronize([makePost(id: "deleted-elsewhere", minutes: 3)])
        // 서버 결과에는 이미 저장된 게시물이 최신입니다.
        synchronize([makePost(id: "server-latest", minutes: 2)])
        completeDownloads()

        XCTAssertEqual(repository.todayIdentifiers, ["server-latest"])
    }

    func testPhotoDeletedDuringDownloadIsNotSaved() {
        let post = makePost(id: "deleted", minutes: 2)

        synchronize([post])
        sut.removePhoto(of: post)
        synchronize([])
        completeDownloads()

        XCTAssertTrue(repository.todayIdentifiers.isEmpty)
    }

    func testDownloadFinishedAfterMidnightIsNotSaved() {
        var current = Calendar.current.startOfDay(for: .now)
            .addingTimeInterval(23 * 3600 + 59 * 60 + 50)
        repository.today = { current }
        sut = makeSUT(now: { current })
        let post = makePost(id: "late-night", createdAt: current.addingTimeInterval(-5))

        synchronize([post])
        XCTAssertEqual(repository.requestedURLs.count, 1)

        // 다운로드가 자정을 넘겨 끝납니다.
        current = current.addingTimeInterval(15)
        completeDownloads()

        XCTAssertTrue(repository.todayIdentifiers.isEmpty)
    }

    func testSynchronizeDoesNotDownloadSamePostTwiceWhileLoading() {
        let latest = makePost(id: "latest", minutes: 2)

        synchronize([latest])
        synchronize([latest])

        XCTAssertEqual(repository.requestedURLs.count, 1)
    }

    func testSynchronizeRemovesTodayPhotosWhenThereIsNoTodayPost() {
        repository.todayIdentifiers = ["deleted-elsewhere"]

        synchronize([makePost(id: "yesterday", createdAt: yesterday())])

        XCTAssertEqual(repository.savedUserIds, ["user"])
        XCTAssertTrue(repository.requestedURLs.isEmpty)
        XCTAssertTrue(repository.todayIdentifiers.isEmpty)
        XCTAssertEqual(repository.reloadCount, 1)
    }

    func testSynchronizeDoesNothingWithoutGroup() {
        userSession.update(makeUser(groupId: nil))

        synchronize([makePost(id: "latest", minutes: 2)])

        XCTAssertTrue(repository.savedUserIds.isEmpty)
        XCTAssertTrue(repository.requestedURLs.isEmpty)
    }

    func testSynchronizeDoesNotSaveWhenDownloadFails() {
        synchronize([makePost(id: "latest", minutes: 2)])
        completeDownloads(with: nil)

        XCTAssertTrue(repository.todayIdentifiers.isEmpty)
        XCTAssertEqual(repository.reloadCount, 0)
    }

    func testRemovePhotoDeletesPostPhotoAndReloadsWidget() {
        repository.todayIdentifiers = ["deleted"]

        sut.removePhoto(of: makePost(id: "deleted", minutes: 1))
        sut.waitUntilIdle()

        XCTAssertTrue(repository.todayIdentifiers.isEmpty)
        XCTAssertEqual(repository.reloadCount, 1)
    }

    private func makeSUT(now: @escaping () -> Date = Date.init) -> WidgetUsecaseImpl {
        WidgetUsecaseImpl(
            repository: repository,
            userSession: userSession,
            workQueue: DispatchQueue(label: "WidgetUsecaseTests"),
            now: now
        )
    }

    private func synchronize(_ posts: [Post]) {
        sut.synchronize(postsByDate: ["posts": posts])
        sut.waitUntilIdle()
    }

    /// 다운로드를 끝내고, 끝난 뒤 작업 큐에 넣은 저장까지 기다립니다.
    private func completeDownloads(with data: Data? = Data([0x01])) {
        repository.completeDownloads(with: data)
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

    private func makeUser(groupId: String?) -> User {
        User(
            uid: "user",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "user",
            birthdayDate: .now,
            gender: .other,
            isPushEnabled: true,
            groupId: groupId
        )
    }
}

/// 오늘 날짜 폴더 하나만 흉내 내고, 다운로드 완료 시점을 테스트가 정하는 위젯 저장소입니다.
private final class FakeWidgetRepository: WidgetRepositoryProtocol {
    /// 오늘 폴더에 저장된 사진의 식별자입니다.
    var todayIdentifiers: [String] = []
    /// 저장소가 오늘로 보는 날짜입니다. 저장은 이 날짜 폴더에 합니다.
    var today: () -> Date = Date.init
    private(set) var savedUserIds: [String] = []
    private(set) var reloadCount = 0
    private(set) var requestedURLs: [URL] = []
    private var pendingDownloads: [(SingleEvent<Data>) -> Void] = []

    func saveUser(_ user: User) {
        savedUserIds.append(user.uid)
    }

    func photoIdentifiers(groupId _: String, date: Date) -> [String] {
        isToday(date) ? todayIdentifiers : []
    }

    func savePhoto(_ data: Data, groupId _: String, identifier: String) throws {
        todayIdentifiers.append(identifier)
    }

    func deletePhoto(groupId _: String, date: Date, identifier: String) {
        guard isToday(date) else { return }
        todayIdentifiers.removeAll { $0 == identifier }
    }

    func fetchImageData(from url: URL) -> Single<Data> {
        requestedURLs.append(url)
        return Single.create { [weak self] observer in
            self?.pendingDownloads.append(observer)
            return Disposables.create()
        }
    }

    func reloadWidget() {
        reloadCount += 1
    }

    /// 내려받는 중인 요청을 모두 끝냅니다. `nil`이면 실패로 끝냅니다.
    func completeDownloads(with data: Data?) {
        let pending = pendingDownloads
        pendingDownloads.removeAll()
        pending.forEach { complete in
            if let data {
                complete(.success(data))
            } else {
                complete(.failure(URLError(.notConnectedToInternet)))
            }
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: today())
    }
}

private final class InMemoryStorage: UserDefaultsStorageProtocol {
    private var values: [String: Any] = [:]

    func set<T>(_ value: T?, forKey key: String) {
        values[key] = value
    }

    func get<T>(forKey key: String) -> T? {
        values[key] as? T
    }

    func remove(_ key: String) {
        values[key] = nil
    }
}
