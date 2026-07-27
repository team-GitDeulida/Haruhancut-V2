//
//  DemoDependencies.swift
//  HomeFeatureV2Demo
//
//  Created by 김동현 on 7/27/26.
//

import Core
import Domain
import RxSwift
import UIKit

enum DemoDependencies {
    static func register() {
        let storage = DemoMemoryStorage()
        let user = DemoContent.makeUser()
        let group = DemoContent.makeGroup(
            user: user
        )
        let userSession = UserSession(
            storage: storage,
            storageKey: "demo.user"
        )
        let groupSession = GroupSession(
            storage: storage,
            storageKey: "demo.group"
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
            dependency: DemoAuthUsecase(
                userSession: userSession
            )
        )
        DIContainer.shared.register(
            GroupUsecaseProtocol.self,
            dependency: DemoGroupUsecase(
                userSession: userSession,
                groupSession: groupSession
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
        values.removeValue(forKey: key)
    }
}

private final class DemoAuthUsecase:
    AuthUsecaseProtocol
{
    private let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    func fetchUser(
        uid: String
    ) -> Single<User?> {
        .just(
            userSession.session?.uid == uid
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
        .just(DemoContent.profileImageURL)
    }

    func updateNicknameAndReloadSession(
        nickname: String
    ) -> Single<User> {
        guard var user = userSession.session
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }

        user.nickname = nickname
        userSession.update(user)
        return .just(user)
    }

    func updateProfileImageAndReloadSession(
        image: UIImage
    ) -> Single<User> {
        guard var user = userSession.session
        else {
            return .error(
                DomainError.missingDomainSession
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
        guard let user = userSession.session
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }
        return .just(.existingUser(user: user))
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
        .just("home-v3-demo-token")
    }

    func syncFcmIfNeeded()
        -> Single<Void>
    {
        .just(())
    }

    func loadAndFetchUser()
        -> Observable<User>
    {
        guard let user = userSession.session
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }
        return .just(user)
    }

    #if DEBUG
    func bootstrapUserSession(
        uid: String
    ) -> Single<User> {
        guard
            let user = userSession.session,
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
    private let userSession: UserSession
    private let groupSession: GroupSession

    init(
        userSession: UserSession,
        groupSession: GroupSession
    ) {
        self.userSession = userSession
        self.groupSession = groupSession
    }

    func updateGroup(
        path: String,
        post: Post
    ) -> Single<Void> {
        upsert(post)
        return .just(())
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
                DomainError.missingDomainSession
            )
        }
        return .just(group)
    }

    func addComment(
        post: Post,
        text: String
    ) -> Single<Void> {
        guard let user = userSession.session
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }

        let comment = Comment(
            commentId:
                UUID().uuidString,
            userId: user.uid,
            nickname: user.nickname,
            profileImageURL:
                user.profileImageURL,
            text: text,
            createdAt: .now
        )

        guard mutatePost(
            identifiedBy: post.postId,
            mutation: {
                $0.comments[
                    comment.commentId
                ] = comment
            }
        )
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }
        return .just(())
    }

    func deleteComment(
        post: Post,
        commentId: String
    ) -> Single<Void> {
        guard mutatePost(
            identifiedBy: post.postId,
            mutation: {
                $0.comments.removeValue(
                    forKey: commentId
                )
            }
        )
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }
        return .just(())
    }

    func uploadImageAndUploadPost(
        image: UIImage
    ) -> Observable<Void> {
        guard let user = userSession.session
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }

        let postID = UUID().uuidString
        upsert(
            Post(
                postId: postID,
                userId: user.uid,
                nickname: user.nickname,
                profileImageURL:
                    user.profileImageURL,
                imageURL:
                    DemoContent.imageURL(
                        seed: postID
                    ),
                createdAt: .now,
                likeCount: 0,
                comments: [:]
            )
        )
        return .just(())
    }

    func deletePostAndReload(
        post: Post
    ) -> Observable<Void> {
        guard var group =
            groupSession.session
        else {
            return .error(
                DomainError.missingDomainSession
            )
        }

        for key in
            Array(group.postsByDate.keys)
        {
            group.postsByDate[key]?
                .removeAll {
                    $0.postId ==
                        post.postId
                }
        }
        groupSession.update(group)
        return .just(())
    }

    private func upsert(_ post: Post) {
        guard var group =
            groupSession.session
        else {
            return
        }

        let key = post.createdAt.toDateKey()
        var posts =
            group.postsByDate[key] ?? []

        if let index = posts.firstIndex(
            where: {
                $0.postId == post.postId
            }
        ) {
            posts[index] = post
        } else {
            posts.append(post)
        }

        group.postsByDate[key] = posts
        groupSession.update(group)
    }

    @discardableResult
    private func mutatePost(
        identifiedBy postID: String,
        mutation: (inout Post) -> Void
    ) -> Bool {
        guard var group =
            groupSession.session
        else {
            return false
        }

        for key in
            Array(group.postsByDate.keys)
        {
            guard
                var posts =
                    group.postsByDate[key],
                let index =
                    posts.firstIndex(
                        where: {
                            $0.postId ==
                                postID
                        }
                    )
            else {
                continue
            }

            mutation(&posts[index])
            group.postsByDate[key] = posts
            groupSession.update(group)
            return true
        }
        return false
    }
}

private enum DemoContent {
    static let profileImageURL =
        URL(
            string:
                "https://picsum.photos/seed/haruhancut-profile/300/300"
        )!

    static func makeUser() -> User {
        User(
            uid: "home-v3-demo-user",
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
                "home-v3-demo-group"
        )
    }

    static func makeGroup(
        user: User
    ) -> SessionGroup {
        let now = Date()
        let posts = [
            makePost(
                id: "today-morning",
                user: user,
                nickname: "하루",
                seed: "morning",
                date: now.addingTimeInterval(
                    -60 * 8
                )
            ),
            makePost(
                id: "today-walk",
                user: user,
                nickname: "하루",
                seed: "walk",
                date: now.addingTimeInterval(
                    -60 * 35
                )
            ),
            makePost(
                id: "today-coffee",
                user: user,
                nickname: "한컷",
                seed: "coffee",
                date: now.addingTimeInterval(
                    -60 * 90
                )
            ),
            makePost(
                id: "today-sunset",
                user: user,
                nickname: "한컷",
                seed: "sunset",
                date: now.addingTimeInterval(
                    -60 * 180
                )
            ),
            makePost(
                id: "calendar-yesterday",
                user: user,
                nickname: "하루",
                seed: "yesterday",
                date: Calendar.current.date(
                    byAdding: .day,
                    value: -1,
                    to: now
                ) ?? now
            ),
            makePost(
                id: "calendar-week",
                user: user,
                nickname: "한컷",
                seed: "week",
                date: Calendar.current.date(
                    byAdding: .day,
                    value: -7,
                    to: now
                ) ?? now
            ),
        ]
        let postsByDate =
            Dictionary(
                grouping: posts,
                by: {
                    $0.createdAt.toDateKey()
                }
            )

        return SessionGroup(
            groupId:
                "home-v3-demo-group",
            groupName: "Home V3 Demo",
            createdAt: .now,
            hostUserId: user.uid,
            inviteCode: "HOMEV3",
            members: [
                user.uid:
                    user.nickname,
            ],
            postsByDate: postsByDate
        )
    }

    static func imageURL(
        seed: String
    ) -> String {
        "https://picsum.photos/seed/\(seed)/800/800"
    }

    private static func makePost(
        id: String,
        user: User,
        nickname: String,
        seed: String,
        date: Date
    ) -> Post {
        let comment = Comment(
            commentId: "\(id)-comment",
            userId: "demo-friend",
            nickname: "오늘",
            text: "좋은 순간이네요!",
            createdAt:
                date.addingTimeInterval(30)
        )

        return Post(
            postId: id,
            userId: user.uid,
            nickname: nickname,
            profileImageURL:
                user.profileImageURL,
            imageURL: imageURL(
                seed: seed
            ),
            createdAt: date,
            likeCount: 0,
            comments: [
                comment.commentId:
                    comment,
            ]
        )
    }
}
