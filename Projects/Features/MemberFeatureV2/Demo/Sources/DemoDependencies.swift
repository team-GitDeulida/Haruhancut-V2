import Core
import Domain
import RxSwift
import UIKit

enum DemoDependencies {
    static func register() {
        let storage =
            DemoMemoryStorage()
        let users =
            DemoContent.makeUsers()
        guard let currentUser =
            users.first
        else {
            return
        }

        let userSession =
            UserSession(
                storage: storage,
                storageKey:
                    "member-v2-demo.user"
            )
        let groupSession =
            GroupSession(
                storage: storage,
                storageKey:
                    "member-v2-demo.group"
            )
        userSession.update(
            currentUser
        )
        groupSession.update(
            DemoContent.makeGroup(
                users: users
            )
        )

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
                    users: users,
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

private final class DemoGroupUsecase:
    GroupUsecaseProtocol
{
    private let groupSession:
        GroupSession

    init(groupSession: GroupSession) {
        self.groupSession =
            groupSession
    }

    func updateBirthdaySettings(
        _ settings:
            GroupBirthdaySettings
    ) -> Single<Void> {
        guard
            var group =
                groupSession.session
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        group.birthdaySettings =
            settings
        groupSession.update(group)
        return .just(())
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
    private var usersByID:
        [String: User]
    private let userSession:
        UserSession

    init(
        users: [User],
        userSession: UserSession
    ) {
        usersByID =
            Dictionary(
                uniqueKeysWithValues:
                    users.map {
                        ($0.uid, $0)
                    }
            )
        self.userSession =
            userSession
    }

    func fetchUser(
        uid: String
    ) -> Single<User?> {
        .just(
            usersByID[uid]
        )
    }

    func updateUser(
        user: User
    ) -> Single<User> {
        usersByID[user.uid] =
            user
        if user.uid ==
            userSession.userId
        {
            userSession.update(user)
        }
        return .just(user)
    }

    func uploadImage(
        user: User,
        image: UIImage
    ) -> Single<URL> {
        .just(
            DemoContent
                .fallbackImageURL
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
        return updateUser(user: user)
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
            DemoContent
                .fallbackImageURL
                .absoluteString
        return updateUser(user: user)
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
        usersByID[user.uid] =
            user
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
            "member-v2-demo-token"
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
            let user = usersByID[
                uid
            ]
        else {
            return .error(
                DomainError.userNotFound
            )
        }
        userSession.update(user)
        return .just(user)
    }
    #endif
}

private enum DemoContent {
    static let fallbackImageURL =
        URL(
            string:
                "https://picsum.photos/id/64/240/240"
        )!

    static func makeUsers()
        -> [User]
    {
        let nicknames = [
            "하루",
            "한컷",
            "동현",
            "은하",
            "초록",
            "여름",
            "구름",
            "모카",
            "노을",
            "겨울",
            "보름",
            "새벽",
            "바다",
            "단풍",
            "별빛",
            "소담",
            "다온",
            "라온",
        ]

        return nicknames
            .enumerated()
            .map {
                index, nickname in
                User(
                    uid:
                        "member-\(index)",
                    registerDate:
                        Date(
                            timeIntervalSince1970:
                                1_700_000_000
                                + Double(
                                    index
                                )
                        ),
                    loginPlatform:
                        .apple,
                    nickname: nickname,
                    profileImageURL:
                        index == 5
                        ? nil
                        : "https://picsum.photos/id/\(60 + index)/240/240",
                    birthdayDate:
                        birthdayDate(
                            for: index
                        ),
                    gender: .other,
                    isPushEnabled:
                        true,
                    groupId:
                        "member-v2-demo-group"
                )
            }
    }

    static func makeGroup(
        users: [User]
    ) -> SessionGroup {
        SessionGroup(
            groupId:
                "member-v2-demo-group",
            groupName: "하루한컷",
            createdAt:
                Date(
                    timeIntervalSince1970:
                        1_700_000_000
                ),
            hostUserId:
                users.first?.uid ?? "",
            inviteCode: "HARU2026",
            members:
                Dictionary(
                    uniqueKeysWithValues:
                        users.enumerated()
                            .map {
                                index, user in
                                (
                                    user.uid,
                                    "\(index)"
                                )
                            }
                ),
            postsByDate: [:]
        )
    }

    private static func birthdayDate(
        for index: Int
    ) -> Date {
        Calendar(
            identifier: .gregorian
        ).date(
            from:
                DateComponents(
                    year:
                        1985
                        + index,
                    month:
                        (
                            index * 2
                            % 12
                        ) + 1,
                    day:
                        (
                            index * 3
                            % 24
                        ) + 1
                )
        ) ?? .now
    }
}
