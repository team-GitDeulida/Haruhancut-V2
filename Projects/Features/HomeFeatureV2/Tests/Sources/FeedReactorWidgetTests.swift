@testable import HomeFeatureV2
import Core
import Domain
import RxSwift
import UIKit
import XCTest

/// `FeedReactor`가 저장된 그룹의 변화와 조회 단계로 피드·로딩·위젯을 맞추는지 확인합니다.
///
/// `FeedReactor`는 세션과 `AuthUsecaseProtocol`을 `@Dependency`로 생성 시점에 꺼내므로,
/// 테스트마다 메모리 저장소 기반 세션과 대역을 `DIContainer`에 등록합니다.
final class FeedReactorWidgetTests: XCTestCase {
    private let disposeBag = DisposeBag()
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

    func testStoredGroupChangeRedrawsFeedAndSynchronizesWidget() {
        let post = makePost(id: "today-post")
        let storedGroup = PublishSubject<HCGroup>()
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(changes: storedGroup),
            groupUsecase: nil,
            widgetUsecase: widgetUsecase
        )
        _ = reactor.state

        storedGroup.onNext(makeGroup(posts: [post]))

        XCTAssertEqual(reactor.currentState.components.map(\.post.postId), ["today-post"])
        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["today-post"]])
    }

    func testEveryFetchSuccessSynchronizesWidget_evenWhenStoredGroupIsUnchanged() {
        // 자정이 지나 다시 조회해도 그룹은 같아 구독은 아무것도 보내지 않습니다.
        let group = makeGroup(posts: [makePost(id: "yesterday-post")])
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { _ in
                .of(
                    FetchResult(status: .loading, value: group),
                    FetchResult(status: .success, value: group)
                )
            }),
            groupUsecase: nil,
            widgetUsecase: widgetUsecase
        )

        reactor.action.onNext(.viewDidAppear)
        reactor.action.onNext(.viewDidAppear)

        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["yesterday-post"], ["yesterday-post"]])
    }

    func testLoadingStaysVisibleUntilServerResponds() {
        let fetch = PublishSubject<FetchResult<HCGroup>>()
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { _ in fetch }),
            groupUsecase: nil
        )

        reactor.action.onNext(.viewDidLoad)
        fetch.onNext(FetchResult(status: .loading, value: nil))
        XCTAssertTrue(reactor.currentState.isLoading)

        fetch.onNext(FetchResult(status: .success, value: makeGroup(posts: [makePost(id: "post")])))
        fetch.onCompleted()
        XCTAssertFalse(reactor.currentState.isLoading)
        XCTAssertEqual(reactor.currentState.components.map(\.post.postId), ["post"])
    }

    func testRefreshTurnsLoadingOnAndOff_whenOnlyServerResultArrives() {
        // refresh()는 .loading 없이 서버 결과만 보냅니다.
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { _ in
                .just(FetchResult(status: .success, value: self.makeGroup(posts: [])))
            }),
            groupUsecase: nil
        )
        var loadingStates: [Bool] = []
        reactor.state
            .map(\.isLoading)
            .distinctUntilChanged()
            .subscribe(onNext: { loadingStates.append($0) })
            .disposed(by: disposeBag)

        reactor.action.onNext(.refresh)

        // 당겨서 새로고침 스피너가 멈추려면 isLoading이 바뀌어야 합니다.
        XCTAssertEqual(loadingStates, [false, true, false])
    }

    func testLoadingTurnsOff_whenResponseIsDropped() {
        // 대상이 바뀌어 응답이 버려지면 .loading만 오고 끝납니다.
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { _ in
                .just(FetchResult(status: .loading, value: nil))
            }),
            groupUsecase: nil
        )

        reactor.action.onNext(.viewDidLoad)

        XCTAssertFalse(reactor.currentState.isLoading)
    }

    func testFetchFailureKeepsFeedAndNotifiesOnce() {
        let cached = makeGroup(posts: [makePost(id: "cached-post")])
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { _ in
                .of(
                    FetchResult(status: .loading, value: cached),
                    FetchResult(status: .failure(TestError()), value: cached)
                )
            }),
            groupUsecase: nil
        )
        var failureCount = 0
        reactor.pulse(\.$loadFailure)
            .compactMap { $0 }
            .subscribe(onNext: { failureCount += 1 })
            .disposed(by: disposeBag)

        reactor.action.onNext(.viewDidLoad)

        XCTAssertEqual(failureCount, 1)
        XCTAssertFalse(reactor.currentState.isLoading)
        XCTAssertEqual(reactor.currentState.components.map(\.post.postId), ["cached-post"])
    }

    func testRefreshAsksServerEvenWithRecentGroup() {
        var forceFlags: [Bool] = []
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { force in
                forceFlags.append(force)
                return .empty()
            }),
            groupUsecase: nil
        )

        reactor.action.onNext(.viewDidLoad)
        reactor.action.onNext(.refresh)

        XCTAssertEqual(forceFlags, [false, true])
    }

    func testAdminPreviewDrawsFeedFromFetchResultWithoutTouchingWidget() {
        let reactor = FeedReactor(
            groupLoader: makeLoader(fetch: { _ in
                .just(FetchResult(status: .success, value: self.makeGroup(posts: [self.makePost(id: "other-group-post")])))
            }),
            groupUsecase: nil,
            widgetUsecase: nil
        )

        reactor.action.onNext(.viewDidLoad)

        XCTAssertEqual(reactor.currentState.components.map(\.post.postId), ["other-group-post"])
    }

    func testDeletingPostRemovesWidgetPhotoAfterServerDeletion() {
        let post = makePost(id: "deleted-post")
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(),
            groupUsecase: StubGroupUsecase(deletion: .just(())),
            widgetUsecase: widgetUsecase
        )

        reactor.action.onNext(.deleteConfirmed(post))

        XCTAssertEqual(widgetUsecase.removedPostIDs, ["deleted-post"])
        XCTAssertFalse(reactor.currentState.isLoading)
    }

    func testWidgetChangesOnlyAfterServerDeletion() {
        let post = makePost(id: "deleted-post")
        let storedGroup = PublishSubject<HCGroup>()
        let deletion = PublishSubject<Void>()
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(changes: storedGroup),
            groupUsecase: StubGroupUsecase(deletion: deletion),
            widgetUsecase: widgetUsecase
        )
        _ = reactor.state
        storedGroup.onNext(makeGroup(posts: [post]))

        reactor.action.onNext(.deleteConfirmed(post))
        // 저장된 그룹에서 먼저 빠져도 서버 응답 전에는 위젯을 맞추지 않습니다.
        storedGroup.onNext(makeGroup(posts: []))

        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["deleted-post"]])
        XCTAssertTrue(widgetUsecase.removedPostIDs.isEmpty)

        deletion.onNext(())

        XCTAssertEqual(widgetUsecase.removedPostIDs, ["deleted-post"])
        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["deleted-post"], []])
    }

    func testFailedDeletionKeepsPostInWidget() {
        let post = makePost(id: "deleted-post")
        let storedGroup = PublishSubject<HCGroup>()
        let deletion = PublishSubject<Void>()
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(changes: storedGroup),
            groupUsecase: StubGroupUsecase(deletion: deletion),
            widgetUsecase: widgetUsecase
        )
        _ = reactor.state
        storedGroup.onNext(makeGroup(posts: [post]))

        reactor.action.onNext(.deleteConfirmed(post))
        // 먼저 빠졌다가 서버 삭제가 실패해 되돌아옵니다.
        storedGroup.onNext(makeGroup(posts: []))
        storedGroup.onNext(makeGroup(posts: [post]))
        deletion.onError(TestError())

        // 게시물이 빠진 그룹으로는 맞추지 않고, 되돌아온 그룹으로 맞춥니다.
        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["deleted-post"], ["deleted-post"]])
        XCTAssertTrue(widgetUsecase.removedPostIDs.isEmpty)
        XCTAssertFalse(reactor.currentState.isLoading)
    }

    func testOverlappingDeletionsSynchronizeWidgetAfterAllFinish() {
        let first = makePost(id: "first")
        let second = makePost(id: "second")
        let storedGroup = PublishSubject<HCGroup>()
        let firstDeletion = PublishSubject<Void>()
        let secondDeletion = PublishSubject<Void>()
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(changes: storedGroup),
            groupUsecase: StubGroupUsecase(deletions: [
                "first": firstDeletion,
                "second": secondDeletion
            ]),
            widgetUsecase: widgetUsecase
        )
        _ = reactor.state
        storedGroup.onNext(makeGroup(posts: [first, second]))

        reactor.action.onNext(.deleteConfirmed(first))
        reactor.action.onNext(.deleteConfirmed(second))
        storedGroup.onNext(makeGroup(posts: [second]))
        storedGroup.onNext(makeGroup(posts: []))

        // 두 번째 삭제가 먼저 성공해도, 첫 번째가 끝나지 않았으므로 위젯을 맞추지 않습니다.
        secondDeletion.onNext(())
        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["first", "second"]])

        // 첫 번째 삭제가 실패해 그 게시물이 돌아온 뒤, 마지막 그룹으로 한 번에 맞춥니다.
        storedGroup.onNext(makeGroup(posts: [first]))
        firstDeletion.onError(TestError())

        XCTAssertEqual(widgetUsecase.removedPostIDs, ["second"])
        XCTAssertEqual(widgetUsecase.synchronizedPostIDs, [["first", "second"], ["first"]])
    }

    func testFailedDeletionKeepsWidgetPhoto() {
        let widgetUsecase = SpyWidgetUsecase()
        let reactor = FeedReactor(
            groupLoader: makeLoader(),
            groupUsecase: StubGroupUsecase(deletion: .error(TestError())),
            widgetUsecase: widgetUsecase
        )

        reactor.action.onNext(.deleteConfirmed(makePost(id: "deleted-post")))

        XCTAssertTrue(widgetUsecase.removedPostIDs.isEmpty)
        XCTAssertFalse(reactor.currentState.isLoading)
    }

    private func makeLoader(
        fetch: @escaping (Bool) -> Observable<FetchResult<HCGroup>> = { _ in .empty() },
        changes: Observable<HCGroup> = .empty()
    ) -> HomeGroupLoader {
        HomeGroupLoader(
            fetch: fetch,
            changes: { changes }
        )
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

private final class InMemoryStorage: StorageProtocol {
    private var values: [String: Any] = [:]

    func write<T: Encodable>(_ value: T, to key: String) {
        values[key] = value
    }

    func read<T: Decodable>(_ key: String) -> T? {
        values[key] as? T
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
    private let deletion: (Post) -> Observable<Void>

    init(deletion: Observable<Void>) {
        self.deletion = { _ in deletion }
    }

    /// 게시물마다 다른 삭제 결과를 냅니다.
    init(deletions: [String: Observable<Void>]) {
        self.deletion = { post in deletions[post.postId] ?? .never() }
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
    func deletePostAndReload(post: Post) -> Observable<Void> { deletion(post) }
}
