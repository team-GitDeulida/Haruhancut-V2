//
//  AuthUsecaseFetchTests.swift
//  DomainTests
//
//  Created by 김동현 on 10/12/26.
//

import Core
import RxSwift
import UIKit
import XCTest
@testable import Domain

/// 유저 조회가 서버 응답(값·없음·실패)에 따라 세션을 다루는지 확인합니다.
final class AuthUsecaseFetchTests: XCTestCase {
    private enum TestError: Error {
        case remote
    }

    private var repository: FakeAuthRepository!
    private var userSession: UserSession!
    private var groupSession: GroupSession!
    private var sut: AuthUsecaseImpl!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repository = FakeAuthRepository()
        userSession = UserSession(
            storage: MemoryStorage(),
            storageKey: "AuthUsecaseFetchTests.user"
        )
        groupSession = GroupSession(
            storage: MemoryStorage(),
            storageKey: "AuthUsecaseFetchTests.group"
        )
        userSession.update(makeUser(nickname: "cached"))
        groupSession.update(makeGroup())
        sut = AuthUsecaseImpl(
            authRepository: repository,
            userSession: userSession,
            groupSession: groupSession,
            fcmTokenStore: FCMTokenStore()
        )
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        sut = nil
        groupSession = nil
        userSession = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - loadAndFetchUser

    func testLoadAndFetchUserSendsCachedUserThenSavesServerUser() {
        repository.fetchUserResponse = .just(makeUser(nickname: "server"))

        let recorder = record(sut.loadAndFetchUser())

        XCTAssertEqual(recorder.values.map(\.nickname), ["cached", "server"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(userSession.session?.nickname, "server")
    }

    func testLoadAndFetchUserKeepsCacheWhenServerFails() {
        repository.fetchUserResponse = .error(TestError.remote)

        let recorder = record(sut.loadAndFetchUser())

        XCTAssertEqual(recorder.values.map(\.nickname), ["cached"])
        XCTAssertEqual(recorder.error as? TestError, .remote)
        XCTAssertEqual(userSession.session?.nickname, "cached")
        XCTAssertNotNil(groupSession.session)
    }

    func testLoadAndFetchUserClearsSessionsWhenServerHasNoUser() {
        repository.fetchUserResponse = .just(nil)

        let recorder = record(sut.loadAndFetchUser())

        XCTAssertEqual(recorder.values.map(\.nickname), ["cached"])
        XCTAssertEqual(recorder.error as? FetchError, .notFound)
        XCTAssertNil(userSession.session)
        XCTAssertNil(groupSession.session)
    }

    func testLoadAndFetchUserKeepsSessionsWhenUserChangedBeforeResponse() {
        // 응답이 오기 전에 다른 유저로 바뀌었습니다.
        repository.fetchUserResponse = .deferred { [userSession] in
            userSession?.update(self.makeUser(uid: "other", nickname: "other"))
            return .just(nil)
        }

        let recorder = record(sut.loadAndFetchUser())

        // 늦게 온 응답은 버리고 끝납니다.
        XCTAssertEqual(recorder.values.map(\.nickname), ["cached"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(userSession.userId, "other")
        XCTAssertNotNil(groupSession.session)
    }

    func testLoadAndFetchUserDoesNotSaveLateUserAfterSignOut() {
        // 응답이 오기 전에 로그아웃했습니다.
        repository.fetchUserResponse = .deferred { [userSession] in
            userSession?.clear()
            return .just(self.makeUser(nickname: "server"))
        }

        let recorder = record(sut.loadAndFetchUser())

        XCTAssertEqual(recorder.values.map(\.nickname), ["cached"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertNil(userSession.session)
    }

    func testLoadAndFetchUserDoesNotSaveLateUserAfterUserChanged() {
        // 응답이 오기 전에 다른 유저로 바뀌었습니다.
        repository.fetchUserResponse = .deferred { [userSession] in
            userSession?.update(self.makeUser(uid: "other", nickname: "other"))
            return .just(self.makeUser(nickname: "server"))
        }

        let recorder = record(sut.loadAndFetchUser())

        // 예전 유저의 응답을 저장하지도, 화면에 보내지도 않습니다.
        XCTAssertEqual(recorder.values.map(\.nickname), ["cached"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(userSession.userId, "other")
        XCTAssertEqual(userSession.session?.nickname, "other")
    }

    func testLoadAndFetchUserFailsWithoutSession() {
        userSession.clear()

        let recorder = record(sut.loadAndFetchUser())

        XCTAssertTrue(recorder.values.isEmpty)
        XCTAssertNotNil(recorder.error)
        XCTAssertEqual(repository.fetchUserCount, 0)
    }

    // MARK: - 쓰기 후 다시 읽기

    func testUpdateNicknameReturnsServerUserOnly() {
        repository.fetchUserResponse = .just(makeUser(nickname: "server"))

        let recorder = record(
            sut.updateNicknameAndReloadSession(nickname: "new").asObservable()
        )

        XCTAssertEqual(recorder.values.map(\.nickname), ["server"])
        XCTAssertEqual(repository.updatedUsers.map(\.nickname), ["new"])
        XCTAssertEqual(userSession.session?.nickname, "server")
    }

    func testUpdateNicknameFailsWhenReloadFails() {
        repository.fetchUserResponse = .error(TestError.remote)

        let recorder = record(
            sut.updateNicknameAndReloadSession(nickname: "new").asObservable()
        )

        // 예전에는 캐시된 유저로 성공했습니다. 이제 다시 읽기 실패를 그대로 알립니다.
        XCTAssertTrue(recorder.values.isEmpty)
        XCTAssertEqual(recorder.error as? TestError, .remote)
    }
}

// MARK: - Helpers

private extension AuthUsecaseFetchTests {
    func record(_ observable: Observable<User>) -> Recorder<User> {
        let recorder = Recorder<User>()
        observable
            .subscribe(
                onNext: { recorder.values.append($0) },
                onError: { recorder.error = $0 },
                onCompleted: { recorder.isCompleted = true }
            )
            .disposed(by: disposeBag)
        return recorder
    }

    func makeUser(uid: String = "user", nickname: String) -> User {
        User(
            uid: uid,
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: nickname,
            birthdayDate: .now,
            gender: .other,
            isPushEnabled: true,
            groupId: "group"
        )
    }

    func makeGroup() -> SessionGroup {
        SessionGroup(
            groupId: "group",
            groupName: "group",
            createdAt: .now,
            hostUserId: "user",
            inviteCode: "code",
            members: [:],
            postsByDate: [:]
        )
    }
}

/// 구독 결과를 모읍니다.
private final class Recorder<Element> {
    var values: [Element] = []
    var error: Error?
    var isCompleted = false
}

/// 유저 조회와 저장만 흉내 내는 저장소입니다.
private final class FakeAuthRepository: AuthRepositoryProtocol {
    var fetchUserResponse: Single<User?> = .never()
    private(set) var fetchUserCount = 0
    private(set) var updatedUsers: [User] = []

    func fetchUser(uid _: String) -> Single<User?> {
        fetchUserCount += 1
        return fetchUserResponse
    }

    func updateUser(user: User) -> Single<User> {
        updatedUsers.append(user)
        return .just(user)
    }

    func loginWithKakao() -> Single<String> { .never() }
    func loginWithApple() -> Single<(String, String)> { .never() }
    func authenticateUser(providerID _: String, idToken _: String, rawNonce _: String?) -> Single<String> { .never() }
    func reauthenticate(platform _: User.LoginPlatform) -> Single<Void> { .never() }
    func signOut() -> Single<Void> { .never() }
    func registerUserToRealtimeDatabase(user: User) -> Single<User> { .never() }
    func deleteAuthUser() -> Single<Void> { .never() }
    func deleteDBUser(uid _: String) -> Single<Void> { .never() }
    func patchUser(uid _: String, fields _: [String: Any]) -> Single<Void> { .never() }
    func uploadImage(user _: User, image _: UIImage) -> Single<URL> { .never() }
    func generateFcmToken() -> Single<String> { .never() }
}
