@testable import HomeFeatureV2
import Core
import Domain
import RxSwift
import UIKit
import XCTest

/// `FeedReactor`가 그룹 조회와 삭제 시점에 위젯 동기화를 요청하는지 확인합니다.
///
/// `FeedReactor`는 세션과 `AuthUsecaseProtocol`을 `@Dependency`로 생성 시점에 꺼내므로,
/// 테스트마다 메모리 저장소 기반 세션과 대역을 `DIContainer`에 등록합니다.
final class FeedReactorWidgetTests: XCTestCase {
    private let user = User(
        uid: "user",
        registerDate: .now,
        loginPlatform: .kakao,
        nickname: "user",
        birthdayDate: .now,
        gender: .other,
        isPushEnabled: true,
        groupId: "group"
    )

    override func setUp() {
        super.setUp()
        let userSession = UserSession(
            storage: InMemoryStorage(),
            storageKey: "FeedReactorWidgetTests.user"
        )
        userSession.update(user)
        DIContainer.shared.register(UserSession.self, dependency: userSession)
        DIContainer.shared.register(
            GroupSession.self,
            dependency: GroupSession(
                storage: InMemoryStorage(),
                storageKey: "FeedReactorWidgetTests.group"
            )
        )
        DIContainer.shared.register(
            AuthUsecaseProtocol.self,
            dependency: StubAuthUsecase()
        )
    }

    func testLoadingFeedSynchronizesWidgetWithLoadedGroup() {
        let post = makePost(id: "today-post")
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            loadGroup: { .just(self.makeGroup(posts: [post])) },
            groupUsecase: nil,
            widgetUsecase: widgetUsecase
        )

        reactor.action.onNext(.viewDidLoad)

        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["today-post"]])
        XCTAssertTrue(widgetUsecase.removedPostIDs.isEmpty)
    }

    func testDeletingPostRemovesWidgetPhotoAfterServerDeletion() {
        let post = makePost(id: "deleted-post")
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            loadGroup: { .empty() },
            groupUsecase: StubGroupUsecase(deletion: .just(())),
            widgetUsecase: widgetUsecase
        )

        reactor.action.onNext(.deleteConfirmed(post))

        XCTAssertEqual(widgetUsecase.removedPostIDs, ["deleted-post"])
        // 남은 오늘 사진으로 위젯을 다시 맞춥니다.
        XCTAssertEqual(widgetUsecase.synchronizedPostIDs.count, 1)
    }

    func testFailedDeletionKeepsWidgetPhoto() {
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            loadGroup: { .empty() },
            groupUsecase: StubGroupUsecase(deletion: .error(TestError())),
            widgetUsecase: widgetUsecase
        )

        reactor.action.onNext(.deleteConfirmed(makePost(id: "deleted-post")))

        XCTAssertTrue(widgetUsecase.removedPostIDs.isEmpty)
        XCTAssertTrue(widgetUsecase.synchronizedPostIDs.isEmpty)
    }

    private func makeGroup(posts: [Post]) -> HCGroup {
        HCGroup(
            groupId: "group",
            groupName: "가족",
            createdAt: .now,
            hostUserId: "user",
            inviteCode: "CODE",
            members: ["user": "joined"],
            postsByDate: ["today": posts]
        )
    }

    private func makePost(id: String) -> Post {
        Post(
            postId: id,
            userId: "user",
            nickname: "user",
            profileImageURL: nil,
            imageURL: "https://example.com/\(id).jpg",
            createdAt: .now,
            likeCount: 0,
            comments: [:]
        )
    }
}

private struct TestError: Error {}

private final class SpyWidgetUsecase: WidgetUsecaseProtocol {
    private(set) var synchronizedPostIDs: [[String]] = []
    private(set) var removedPostIDs: [String] = []

    func synchronize(postsByDate: [String: [Post]]) {
        synchronizedPostIDs.append(
            postsByDate.values.flatMap { $0 }.map(\.postId).sorted()
        )
    }

    func removePhoto(of post: Post) {
        removedPostIDs.append(post.postId)
    }
}

private final class InMemoryStorage: StorageType {
    private var values: [String: Data] = [:]

    func write(_ data: Data, to key: String) {
        values[key] = data
    }

    func read(_ key: String) -> Data? {
        values[key]
    }

    func remove(_ key: String) {
        values[key] = nil
    }
}

/// `FeedReactor`가 쓰는 `loadAndFetchUser`만 값을 내보내지 않고 끝납니다.
private final class StubAuthUsecase: AuthUsecaseProtocol {
    func fetchUser(uid _: String) -> Single<User?> { .never() }
    func updateUser(user _: User) -> Single<User> { .never() }
    func uploadImage(user _: User, image _: UIImage) -> Single<URL> { .never() }
    func updateNicknameAndReloadSession(nickname _: String) -> Single<User> { .never() }
    func updateProfileImageAndReloadSession(image _: UIImage) -> Single<User> { .never() }
    func signIn(platform _: User.LoginPlatform) -> Single<SignInResult> { .never() }
    func signUp(user _: User, profileImage _: UIImage?) -> Single<Void> { .never() }
    func signOut() -> Single<Void> { .never() }
    func deleteUserAuthAndData() -> Single<Void> { .never() }
    func generateFcmToken() -> Single<String> { .never() }
    func syncFcmIfNeeded() -> Single<Void> { .never() }
    func loadAndFetchUser() -> Observable<User> { .empty() }
    #if DEBUG
    func bootstrapUserSession(uid _: String) -> Single<User> { .never() }
    #endif
}

/// `FeedReactor`가 쓰는 `deletePostAndReload`만 지정한 결과를 내보냅니다.
private final class StubGroupUsecase: GroupUsecaseProtocol {
    private let deletion: Observable<Void>

    init(deletion: Observable<Void>) {
        self.deletion = deletion
    }

    func updateGroup(path _: String, post _: Post) -> Single<Void> { .never() }
    func observeValueStream<T: Decodable>(path _: String, type _: T.Type) -> Observable<T> { .never() }
    func deleteValue(path _: String) -> Single<Void> { .never() }
    func joinAndUpdateGroup(inviteCode _: String) -> Single<Void> { .never() }
    func createAndUpdateGroup(groupName _: String) -> Single<Void> { .never() }
    func loadAndFetchGroup() -> Observable<HCGroup> { .never() }
    func addComment(post _: Post, text _: String) -> Single<Void> { .never() }
    func deleteComment(post _: Post, commentId _: String) -> Single<Void> { .never() }
    func uploadImageAndUploadPost(image _: UIImage) -> Observable<Void> { .never() }
    func deletePostAndReload(post _: Post) -> Observable<Void> { deletion }
}
