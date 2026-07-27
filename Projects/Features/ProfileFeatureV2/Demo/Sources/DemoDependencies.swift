import Core
import Domain
import RxSwift
import UIKit

enum DemoDependencies {
    static func register() {
        let storage =
            DemoMemoryStorage()
        let user =
            DemoContent.makeUser()
        let group =
            DemoContent.makeGroup(
                user: user
            )
        let userSession =
            UserSession(
                storage: storage,
                storageKey:
                    "profile-v2-demo.user"
            )
        let groupSession =
            GroupSession(
                storage: storage,
                storageKey:
                    "profile-v2-demo.group"
            )

        userSession.update(user)
        groupSession.update(group)

        DIContainer.shared.register(
            UserSession.self,
            dependency: userSession
        )
        DIContainer.shared.register(
            GroupSession.self,
            dependency: groupSession
        )
        DIContainer.shared.register(
            AuthUsecaseProtocol.self,
            dependency:
                DemoAuthUsecase(
                    userSession:
                        userSession
                )
        )
        DIContainer.shared.register(
            GroupUsecaseProtocol.self,
            dependency:
                DemoGroupUsecase(
                    groupSession:
                        groupSession
                )
        )
    }
}

private final class DemoMemoryStorage:
    UserDefaultsStorageProtocol
{
    private var values:
        [String: Any] = [:]

    func set<T>(
        _ value: T?,
        forKey key: String
    ) {
        values[key] = value
    }

    func get<T>(
        forKey key: String
    ) -> T? {
        values[key] as? T
    }

    func remove(_ key: String) {
        values.removeValue(
            forKey: key
        )
    }
}

private final class DemoAuthUsecase:
    AuthUsecaseProtocol
{
    private let userSession:
        UserSession

    init(
        userSession: UserSession
    ) {
        self.userSession =
            userSession
    }

    func fetchUser(
        uid: String
    ) -> Single<User?> {
        .just(
            userSession.session?.uid
                == uid
                ? userSession.session
                : nil
        )
    }

    func updateUser(
        user: User
    ) -> Single<User> {
        userSession.update(user)
        return .just(user)
    }

    func uploadImage(
        user: User,
        image: UIImage
    ) -> Single<URL> {
        .just(
            DemoContent.profileImageURL
        )
    }

    func updateNicknameAndReloadSession(
        nickname: String
    ) -> Single<User> {
        guard
            var user =
                userSession.session
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        user.nickname = nickname
        userSession.update(user)
        return .just(user)
    }

    func updateProfileImageAndReloadSession(
        image: UIImage
    ) -> Single<User> {
        guard
            var user =
                userSession.session
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        user.profileImageURL =
            DemoContent.profileImageURL
                .absoluteString
        userSession.update(user)
        return .just(user)
    }

    func signIn(
        platform: User.LoginPlatform
    ) -> Single<SignInResult> {
        guard
            let user =
                userSession.session
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        return .just(
            .existingUser(user: user)
        )
    }

    func signUp(
        user: User,
        profileImage: UIImage?
    ) -> Single<Void> {
        userSession.update(user)
        return .just(())
    }

    func signOut() -> Single<Void> {
        userSession.clear()
        return .just(())
    }

    func deleteUserAuthAndData()
        -> Single<Void>
    {
        userSession.clear()
        return .just(())
    }

    func generateFcmToken()
        -> Single<String>
    {
        .just(
            "profile-v2-demo-token"
        )
    }

    func syncFcmIfNeeded()
        -> Single<Void>
    {
        .just(())
    }

    func loadAndFetchUser()
        -> Observable<User>
    {
        guard
            let user =
                userSession.session
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        return .just(user)
    }

    #if DEBUG
    func bootstrapUserSession(
        uid: String
    ) -> Single<User> {
        guard
            let user =
                userSession.session,
            user.uid == uid
        else {
            return .error(
                DomainError.userNotFound
            )
        }
        return .just(user)
    }
    #endif
}

private final class DemoGroupUsecase:
    GroupUsecaseProtocol
{
    private let groupSession:
        GroupSession

    init(
        groupSession: GroupSession
    ) {
        self.groupSession =
            groupSession
    }

    func updateGroup(
        path: String,
        post: Post
    ) -> Single<Void> {
        .just(())
    }

    func observeValueStream<
        T: Decodable
    >(
        path: String,
        type: T.Type
    ) -> Observable<T> {
        .empty()
    }

    func deleteValue(
        path: String
    ) -> Single<Void> {
        .just(())
    }

    func joinAndUpdateGroup(
        inviteCode: String
    ) -> Single<Void> {
        .just(())
    }

    func createAndUpdateGroup(
        groupName: String
    ) -> Single<Void> {
        .just(())
    }

    func loadAndFetchGroup()
        -> Observable<HCGroup>
    {
        guard
            let group =
                groupSession.entity
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        return .just(group)
    }

    func addComment(
        post: Post,
        text: String
    ) -> Single<Void> {
        .just(())
    }

    func deleteComment(
        post: Post,
        commentId: String
    ) -> Single<Void> {
        .just(())
    }

    func uploadImageAndUploadPost(
        image: UIImage
    ) -> Observable<Void> {
        .just(())
    }

    func deletePostAndReload(
        post: Post
    ) -> Observable<Void> {
        .just(())
    }
}

private enum DemoContent {
    static let profileImageURL =
        URL(
            string:
                "https://picsum.photos/seed/profile-v2-user/300/300"
        )!

    static func makeUser() -> User {
        User(
            uid: "profile-v2-demo-user",
            registerDate: .now,
            loginPlatform: .apple,
            nickname: "하루",
            profileImageURL:
                profileImageURL
                    .absoluteString,
            birthdayDate: .now,
            gender: .other,
            isPushEnabled: true,
            groupId:
                "profile-v2-demo-group"
        )
    }

    static func makeGroup(
        user: User
    ) -> SessionGroup {
        let posts = (0..<15).map {
            index in
            Post(
                postId:
                    "profile-post-\(index)",
                userId: user.uid,
                nickname: user.nickname,
                profileImageURL:
                    user.profileImageURL,
                imageURL:
                    "https://picsum.photos/seed/profile-v2-\(index)/600/900",
                createdAt:
                    Date().addingTimeInterval(
                        -Double(index) * 3600
                    ),
                likeCount: index,
                comments: [:]
            )
        }

        return SessionGroup(
            groupId:
                "profile-v2-demo-group",
            groupName: "Profile V2 Demo",
            createdAt: .now,
            hostUserId: user.uid,
            inviteCode: "PROFILEV2",
            members: [
                user.uid: user.nickname,
            ],
            postsByDate:
                Dictionary(
                    grouping: posts,
                    by: {
                        $0.createdAt
                            .toDateKey()
                    }
                )
        )
    }
}
