import Core
import Domain
import RxCocoa
import RxSwift
import UIKit
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

/// 프로필 화면이 저장된 유저·그룹을 구독해 다시 읽지 않고도 바뀐 값을 그리는지 확인합니다.
final class ProfileViewModelTests: XCTestCase {
    private let disposeBag = DisposeBag()
    private var userSession: UserSession!
    private var authUsecase: StubAuthUsecase!
    private var groupUsecase: StubGroupUsecase!
    private var sut: ProfileViewModel!

    override func setUp() {
        super.setUp()
        userSession = UserSession(
            storage: InMemoryStorage(),
            storageKey: "ProfileViewModelTests.user"
        )
        userSession.update(makeUser(nickname: "before"))
        authUsecase = StubAuthUsecase()
        groupUsecase = StubGroupUsecase()
        sut = ProfileViewModel(
            userSession: userSession,
            authUsecase: authUsecase,
            groupUsecase: groupUsecase
        )
    }

    func testProfileFollowsStoredUserAndGroupWithoutReading() {
        let output = sut.transform(input: makeInput())
        var nicknames: [String] = []
        var postIDs: [[String]] = []
        output.user
            .drive(onNext: { nicknames.append($0.nickname) })
            .disposed(by: disposeBag)
        output.myPosts
            .drive(onNext: { postIDs.append($0.map(\.postId)) })
            .disposed(by: disposeBag)

        authUsecase.storedUser.onNext(makeUser(nickname: "before"))
        groupUsecase.storedGroup.onNext(makeGroup(posts: [makePost(id: "mine")]))
        // 닉네임을 바꾸거나 다른 화면에서 게시물을 지우면 저장된 값이 바뀝니다.
        authUsecase.storedUser.onNext(makeUser(nickname: "after"))
        groupUsecase.storedGroup.onNext(makeGroup(posts: []))

        XCTAssertEqual(nicknames, ["before", "after"])
        XCTAssertEqual(postIDs, [["mine"], []])
    }

    func testProfileAsksServerOnAppearAndAlwaysOnReload() {
        let viewWillAppear = PublishSubject<Void>()
        let reload = PublishSubject<Void>()
        _ = sut.transform(
            input: makeInput(reload: reload, viewWillAppear: viewWillAppear)
        )

        viewWillAppear.onNext(())
        reload.onNext(())

        XCTAssertEqual(authUsecase.loadCount, 1)
        // 처음에는 최근에 받은 그룹이면 서버를 건너뛰고, 새로고침하면 항상 서버에 묻습니다.
        XCTAssertEqual(groupUsecase.requestedForces, [false, true])
    }

    private func makeInput(
        reload: Observable<Void> = .never(),
        viewWillAppear: Observable<Void> = .never()
    ) -> ProfileViewModel.Input {
        ProfileViewModel.Input(
            profileImageTapped: .never(),
            profileImageEditTapped: .never(),
            nicknameEditTapped: .never(),
            birthdayEditTapped: .never(),
            settingTapped: .never(),
            imageTapped: .never(),
            reload: reload,
            viewWillAppear: viewWillAppear
        )
    }

    private func makeUser(nickname: String) -> User {
        User(
            uid: "user",
            registerDate: Date(timeIntervalSince1970: 0),
            loginPlatform: .kakao,
            nickname: nickname,
            birthdayDate: Date(timeIntervalSince1970: 0),
            gender: .other,
            isPushEnabled: true,
            groupId: "group"
        )
    }

    private func makeGroup(posts: [Post]) -> HCGroup {
        HCGroup(
            groupId: "group",
            groupName: "가족",
            createdAt: Date(timeIntervalSince1970: 0),
            hostUserId: "user",
            inviteCode: "CODE",
            members: ["user": "joined"],
            postsByDate: posts.isEmpty ? [:] : ["today": posts]
        )
    }

    private func makePost(id: String) -> Post {
        Post(
            postId: id,
            userId: "user",
            nickname: "하루",
            profileImageURL: nil,
            imageURL: "https://example.com/\(id).jpg",
            createdAt: Date(timeIntervalSince1970: 0),
            likeCount: 0,
            comments: [:]
        )
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

/// 저장된 유저 구독과 서버 조회 횟수만 흉내 냅니다.
private final class StubAuthUsecase: AuthUsecaseProtocol {
    let storedUser = PublishSubject<User>()
    private(set) var loadCount = 0

    func observeUser() -> Observable<User> { storedUser }
    func loadAndFetchUser() -> Observable<User> {
        loadCount += 1
        return .empty()
    }

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
    #if DEBUG
    func bootstrapUserSession(uid _: String) -> Single<User> { .never() }
    #endif
}

/// 저장된 그룹 구독과 서버 조회 요청만 흉내 냅니다.
private final class StubGroupUsecase: GroupUsecaseProtocol {
    let storedGroup = PublishSubject<HCGroup>()
    /// 조회를 요청한 순서입니다. `false`는 `fetchGroupResult()`, `true`는 `refreshGroupResult()`입니다.
    private(set) var requestedForces: [Bool] = []

    func observeGroup() -> Observable<HCGroup> { storedGroup }
    func fetchGroupResult() -> Observable<FetchResult<HCGroup>> {
        requestedForces.append(false)
        return .empty()
    }

    func refreshGroupResult() -> Observable<FetchResult<HCGroup>> {
        requestedForces.append(true)
        return .empty()
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
    func deletePostAndReload(post _: Post) -> Observable<Void> { .never() }
}
