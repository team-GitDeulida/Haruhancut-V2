import Core
import Domain
import RxSwift
import UIKit
import XCTest

final class FCMTokenSyncTests: XCTestCase {
    func testSyncFcmIfNeededUpdatesServerWhenTokensDiffer() async throws {
        let serverUser = makeUser(fcmToken: "server-token")
        let repository = FCMAuthRepositoryStub(
            serverUser: serverUser,
            localToken: "local-token"
        )
        let (sut, userSession) = makeSUT(
            repository: repository,
            sessionUser: serverUser
        )

        try await sut.syncFcmIfNeeded().value

        XCTAssertEqual(repository.generateFcmTokenCallCount, 1)
        XCTAssertEqual(repository.patchUserCallCount, 1)
        XCTAssertEqual(
            repository.lastPatchedFields?["fcmToken"] as? String,
            "local-token"
        )
        XCTAssertEqual(userSession.fcmToken, "local-token")
    }

    func testSyncFcmIfNeededSkipsServerUpdateWhenTokensMatch() async throws {
        let serverUser = makeUser(fcmToken: "same-token")
        let repository = FCMAuthRepositoryStub(
            serverUser: serverUser,
            localToken: "same-token"
        )
        let (sut, userSession) = makeSUT(
            repository: repository,
            sessionUser: serverUser
        )

        try await sut.syncFcmIfNeeded().value

        XCTAssertEqual(repository.generateFcmTokenCallCount, 1)
        XCTAssertEqual(repository.patchUserCallCount, 0)
        XCTAssertEqual(userSession.fcmToken, "same-token")
    }

    func testExistingUserSignInSynchronizesLatestFcmToken() async throws {
        let serverUser = makeUser(fcmToken: "server-token")
        let repository = FCMAuthRepositoryStub(
            serverUser: serverUser,
            localToken: "local-token"
        )
        let (sut, userSession) = makeSUT(repository: repository)

        let result = try await sut.signIn(platform: .kakao).value

        guard case .existingUser(let signedInUser) = result else {
            return XCTFail("기존 사용자 로그인 결과가 필요합니다.")
        }
        XCTAssertEqual(signedInUser.uid, serverUser.uid)
        XCTAssertEqual(repository.generateFcmTokenCallCount, 1)
        XCTAssertEqual(repository.patchUserCallCount, 1)
        XCTAssertEqual(userSession.fcmToken, "local-token")
    }

    func testExistingUserSignInSucceedsWhenFcmSyncFails() async throws {
        let serverUser = makeUser(fcmToken: "server-token")
        let repository = FCMAuthRepositoryStub(
            serverUser: serverUser,
            localToken: "local-token"
        )
        repository.fcmTokenError = FCMTokenSyncTestError.unavailable
        let (sut, userSession) = makeSUT(repository: repository)

        let result = try await sut.signIn(platform: .kakao).value

        guard case .existingUser(let signedInUser) = result else {
            return XCTFail("FCM 동기화 실패가 로그인을 막으면 안 됩니다.")
        }
        XCTAssertEqual(signedInUser.uid, serverUser.uid)
        XCTAssertEqual(repository.patchUserCallCount, 0)
        XCTAssertEqual(userSession.session?.uid, serverUser.uid)
    }

    func testSignUpSynchronizesLatestFcmTokenAfterSessionIsCreated() async throws {
        let newUser = makeUser(fcmToken: "noToken")
        let repository = FCMAuthRepositoryStub(
            serverUser: newUser,
            localToken: "local-token"
        )
        let (sut, userSession) = makeSUT(repository: repository)

        try await sut.signUp(user: newUser, profileImage: nil).value

        XCTAssertEqual(repository.generateFcmTokenCallCount, 1)
        XCTAssertEqual(repository.patchUserCallCount, 1)
        XCTAssertEqual(userSession.fcmToken, "local-token")
    }

    private func makeSUT(
        repository: FCMAuthRepositoryStub,
        sessionUser: User? = nil
    ) -> (AuthUsecaseImpl, UserSession) {
        let storage = FCMTokenSyncTestStorage()
        let userSession = UserSession(
            storage: storage,
            storageKey: "fcm-test-user"
        )
        let groupSession = GroupSession(
            storage: storage,
            storageKey: "fcm-test-group"
        )
        if let sessionUser {
            userSession.update(sessionUser)
        }

        let sut = AuthUsecaseImpl(
            authRepository: repository,
            userSession: userSession,
            groupSession: groupSession,
            fcmTokenStore: FCMTokenStore()
        )
        return (sut, userSession)
    }

    private func makeUser(fcmToken: String?) -> User {
        User(
            uid: "user-id",
            registerDate: Date(timeIntervalSince1970: 0),
            loginPlatform: .kakao,
            nickname: "하루",
            fcmToken: fcmToken,
            birthdayDate: Date(timeIntervalSince1970: 0),
            gender: .other,
            isPushEnabled: true
        )
    }
}

private enum FCMTokenSyncTestError: Error {
    case unavailable
}

private final class FCMTokenSyncTestStorage: UserDefaultsStorageProtocol {
    private var values: [String: Any] = [:]

    func set<T>(_ value: T?, forKey key: String) {
        values[key] = value
    }

    func get<T>(forKey key: String) -> T? {
        values[key] as? T
    }

    func remove(_ key: String) {
        values.removeValue(forKey: key)
    }
}

private final class FCMAuthRepositoryStub: AuthRepositoryProtocol {
    var serverUser: User?
    var localToken: String
    var fcmTokenError: Error?
    private(set) var generateFcmTokenCallCount = 0
    private(set) var patchUserCallCount = 0
    private(set) var lastPatchedFields: [String: Any]?

    init(serverUser: User, localToken: String) {
        self.serverUser = serverUser
        self.localToken = localToken
    }

    func loginWithKakao() -> Single<String> {
        .just("kakao-token")
    }

    func loginWithApple() -> Single<(String, String)> {
        .just(("apple-token", "nonce"))
    }

    func authenticateUser(
        providerID: String,
        idToken: String,
        rawNonce: String?
    ) -> Single<String> {
        guard let uid = serverUser?.uid else {
            return .error(FCMTokenSyncTestError.unavailable)
        }
        return .just(uid)
    }

    func reauthenticate(platform: User.LoginPlatform) -> Single<Void> {
        .just(())
    }

    func signOut() -> Single<Void> {
        .just(())
    }

    func registerUserToRealtimeDatabase(user: User) -> Single<User> {
        .just(user)
    }

    func fetchUser(uid: String) -> Single<User?> {
        .just(serverUser)
    }

    func updateUser(user: User) -> Single<User> {
        serverUser = user
        return .just(user)
    }

    func deleteAuthUser() -> Single<Void> {
        .just(())
    }

    func deleteDBUser(uid: String) -> Single<Void> {
        .just(())
    }

    func patchUser(
        uid: String,
        fields: [String: Any]
    ) -> Single<Void> {
        patchUserCallCount += 1
        lastPatchedFields = fields
        if let token = fields["fcmToken"] as? String {
            serverUser?.fcmToken = token
        }
        return .just(())
    }

    func uploadImage(
        user: User,
        image: UIImage
    ) -> Single<URL> {
        .just(URL(string: "https://example.com/image.jpg")!)
    }

    func generateFcmToken() -> Single<String> {
        generateFcmTokenCallCount += 1
        if let fcmTokenError {
            return .error(fcmTokenError)
        }
        return .just(localToken)
    }
}
