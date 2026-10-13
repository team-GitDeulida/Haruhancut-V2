//
//  AuthUsecase.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import RxSwift
import Core
import UIKit

public enum SocialAuthPayload {
    case kakao(token: String)
    case apple(idToken: String, rawNonce: String)
    
    public var platform: User.LoginPlatform {
        switch self {
        case .kakao: .kakao
        case .apple: .apple
        }
    }
}

public enum SignInResult {
    case existingUser(user: User)
    case newUser(platform: User.LoginPlatform)
}

public protocol AuthUsecaseProtocol {

    func fetchUser(uid: String) -> Single<User?>
    func updateUser(user: User) -> Single<User>
    func uploadImage(user: User, image: UIImage) -> Single<URL>
    func updateNicknameAndReloadSession(nickname: String) -> Single<User>
    func updateProfileImageAndReloadSession(image: UIImage) -> Single<User>
    /// 푸시 알림 설정을 세션에 먼저 반영하고 서버에 저장합니다. 저장에 실패하면 세션을 원래 값으로 되돌립니다.
    func updatePushEnabled(_ isEnabled: Bool) -> Single<User>
    
    // MARK: - Sign
    func signIn(platform: User.LoginPlatform) -> Single<SignInResult>
    func signUp(user: User, profileImage: UIImage?) -> Single<Void>
    func signOut() -> Single<Void>
    func deleteUserAuthAndData() -> Single<Void>
    
    // MARK: - FCM
    func generateFcmToken() -> Single<String>
    func syncFcmIfNeeded() -> Single<Void>
    func loadAndFetchUser() -> Observable<User>

    // MARK: - Test
    #if DEBUG
    func bootstrapUserSession(uid: String) -> Single<User>
    #endif
}

public extension AuthUsecaseProtocol {
    /// 푸시 설정을 저장하지 않는 Demo·테스트 구현을 위한 기본 동작입니다.
    func updatePushEnabled(_ isEnabled: Bool) -> Single<User> {
        .error(DomainError.missingDomainSession)
    }
}

public final class AuthUsecaseImpl: AuthUsecaseProtocol {

    private let repository: AuthRepositoryProtocol
    private let userSession: UserSession
    private let groupSession: GroupSession
    private let fcmTokenStore: FCMTokenStore
    /// 같은 유저 요청을 합치고, 10초 안에 받은 유저면 `fetch`가 서버를 건너뛰게 한다
    private let userRequests = FetchRequests<User>(maxAge: 10)
    
    public init(authRepository: AuthRepositoryProtocol,
                userSession: UserSession,
                groupSession: GroupSession,
                fcmTokenStore: FCMTokenStore
    ) {
        self.repository = authRepository
        self.userSession = userSession
        self.groupSession = groupSession
        self.fcmTokenStore = fcmTokenStore
    }
    
    
    /// 유저 정보 가져오기
    /// - Parameter user: uid
    /// - Returns: 유저
    public func fetchUser(uid: String) -> Single<User?> {
        return repository.fetchUser(uid: uid)
    }
    
    /// 유저 업데이트
    /// - Parameter user: 유저
    /// - Returns: 성공유무
    public func updateUser(user: User) -> Single<User> {
        return repository.updateUser(user: user)
    }
    
    /// 이미지 업로드
    /// - Parameters:
    ///   - user: 유저
    ///   - image: 이미지
    /// - Returns: 이미지url
    public func uploadImage(user: User, image: UIImage) -> Single<URL> {
        return repository.uploadImage(user: user, image: image)
    }
    
    
    /// 닉네임 업데이트 및 세션 갱신
    /// - Parameter nickname: 새 닉네임
    /// - Returns: 변경된 유저
    public func updateNicknameAndReloadSession(nickname: String) -> Single<User> {
        guard var currentUser = userSession.session else {
            return .error(DomainError.missingDomainSession)
        }
        
        currentUser.nickname = nickname
        let repository = repository
        return writeUserThenReload(userId: currentUser.uid) {
            repository.updateUser(user: currentUser).map { _ in () }
        }
    }
    
    public func updatePushEnabled(_ isEnabled: Bool) -> Single<User> {
        guard let userId = userSession.userId else {
            return .error(DomainError.missingDomainSession)
        }

        let repository = repository
        // 세션을 먼저 바꾸고 서버에 저장한다. 실패하면 Fetcher가 되돌린다
        return userFetcher(userId: userId)
            .update({ user in
                user.isPushEnabled = isEnabled
            }, remote: { user in
                repository.updateUser(user: user).map { _ in () }
            })
    }

    public func updateProfileImageAndReloadSession(image: UIImage) -> Single<User> {
        guard let currentUser = userSession.session else {
            return .error(DomainError.missingDomainSession)
        }
        
        let repository = repository
        return repository.uploadImage(user: currentUser, image: image)
            .flatMap { url -> Single<User> in
                var updatedUser = currentUser
                updatedUser.profileImageURL = url.absoluteString
                return self.writeUserThenReload(userId: currentUser.uid) {
                    repository.updateUser(user: updatedUser).map { _ in () }
                }
            }
    }
}

// MARK: - Sign in(Private)
extension AuthUsecaseImpl {
    
    /// Firebase 인증
    ///
    /// - 인증 결과 값은 필요 없고
    /// - 성공 / 실패 여부만 중요
    /// → Completable 로 표현
    private func authenticate(payload: SocialAuthPayload) -> Single<String> {
        switch payload {
        case .kakao(let token):
            return repository.authenticateUser(providerID: "kakao",
                                    idToken: token,
                                    rawNonce: nil)
            
        case .apple(let idToken, let rawNonce):
            return repository.authenticateUser(providerID: "apple",
                                    idToken: idToken,
                                    rawNonce: rawNonce)
        }
    }
    
    /// 기존 유저 / 신규 유저 판별
    ///
    /// - 기존 유저: 홈으로 이동
    /// - 신규 유저: 온보딩으로 이동
    /// - 분기 결과는 side-effect로만 처리
    private func resolveUser(uid: String, platform: User.LoginPlatform) -> Single<SignInResult> {
        self.repository.fetchUser(uid: uid)
            .map { user in
                if let user {
                    return .existingUser(user: user)
                } else {
                    return .newUser(platform: platform)
                }
            }
    }
    
    /// 소셜 로그인
    /// - Parameter platform: 플랫폼
    /// - Returns: SocialAuthPayload
    private func loginWith(with platform: User.LoginPlatform) -> Single<SocialAuthPayload> {
        switch platform {
        case .kakao:
            return repository.loginWithKakao() // Single<String>
                .map { SocialAuthPayload.kakao(token: $0) }
        case .apple: // Observable<Result<(String, String), LoginError>>
            return repository.loginWithApple()
                .map { SocialAuthPayload.apple(idToken: $0.0, rawNonce: $0.1) }
        }
    }
}

// MARK: - Sign in / Sign Up / LogOut
extension AuthUsecaseImpl {
    public func signUp(user: User, profileImage: UIImage?) -> Single<Void> {
        repository.registerUserToRealtimeDatabase(user: user)
            .flatMap { registeredUser -> Single<User> in
                
                // 이미지가 없는 경우
                guard let image = profileImage else {
                    // 이미지가 없다면 바로 성공(Void) 반환
                    return .just(registeredUser)
                }
                
                // 이미지가 있는 경우
                return self.uploadImage(user: registeredUser, image: image)
                    .flatMap { url in
                        var updated = registeredUser
                        updated.profileImageURL = url.absoluteString
                        return self.updateUser(user: updated)
                    }
            }
            .flatMap { savedUser -> Single<Void> in
                // 최종 유저를 세션에 저장한 뒤 APNs 등록 완료 여부를 다시 확인한다.
                // APNs 콜백과 회원가입 완료가 엇갈려도 마지막에 FCM 동기화를 재시도한다.
                self.userSession.update(savedUser)

                return self.syncFcmIfNeeded()
                    .catch { error in
                        Logger.d(
                            "회원가입 후 FCM 토큰 동기화 실패: \(error.localizedDescription)"
                        )
                        return .just(())
                    }
            }
    }
    
    public func signIn(platform: User.LoginPlatform) -> Single<SignInResult> {
        self.loginWith(with: platform)
            .flatMap { payload in
                Logger.d("인증 진행")
                return self.authenticate(payload: payload)
            }
            .flatMap { uid in
                Logger.d("firebase 진행")
                return self.resolveUser(uid: uid, platform: platform)
            }
            .flatMap { result -> Single<SignInResult> in
                guard case .existingUser(let user) = result else {
                    return .just(result)
                }

                Logger.d("기존 사용자")
                self.userSession.update(user)

                return self.syncFcmIfNeeded()
                    .map { result }
                    .catch { error in
                        Logger.d("로그인 후 FCM 토큰 동기화 실패: \(error.localizedDescription)")
                        return .just(result)
                    }
            }
    }
    
    public func signOut() -> Single<Void> {
        
        return self.repository.signOut()
            .do(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.userSession.clear()
                self.groupSession.clear()
            })
    }
    
    public func deleteUserAuthAndData() -> Single<Void> {
        
        guard let uid = userSession.userId,
              let platform = userSession.platform else {
            return .error(DomainError.missingDomainSession)
        }
        
        return repository.reauthenticate(platform: platform)
            .flatMap {
                self.repository.deleteDBUser(uid: uid)
            }
            .flatMap {
                self.repository.deleteAuthUser()
            }
            .do(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.userSession.clear()
                self.groupSession.clear()
            })
    }
}

// MARK: - FCM
extension AuthUsecaseImpl {
    
    // MARK: - FCM 토큰 생성(회원가입시 명시적)
    public func generateFcmToken() -> Single<String> {
        return repository.generateFcmToken()
    }
    
    // MARK: - 로컬 값(최신) 서버 값(최신 아닐 가능성) 비교 후 서버 값 최신화
    public func syncFcmIfNeeded() -> Single<Void> {
        
        // 세션이 없으면 조기리턴
        guard let sessionUser = userSession.session else {
            return .just(())
        }

        return repository.generateFcmToken()
            .do(onSuccess: { localToken in
                self.fcmTokenStore.latestToken = localToken
            })
            .flatMap { localToken in
                self.repository.fetchUser(uid: sessionUser.uid)
                    .flatMap { serverUser -> Single<Void> in
                        let serverToken = serverUser?.fcmToken

                        // 값이 같으면 아무것도 안 함
                        if serverToken == localToken {
                            return .just(())
                        }

                        // 다르면 patch
                        return self.repository.patchUser(
                            uid: sessionUser.uid,
                            fields: ["fcmToken": localToken])
                        .do(onSuccess: {
                            self.userSession.update(\.fcmToken, localToken)
                            Logger.d("FCM 토큰 동기화 완료")
                        })
                    }
            }
    }
}

extension AuthUsecaseImpl {
    /// 캐시된 유저를 먼저 보내고 서버 유저로 갱신한다
    /// - 서버에 유저가 없으면 세션을 지우고 `FetchError.notFound`로 끝낸다
    /// - 서버에 확인하지 못하면 캐시를 유지하고 그 에러로 끝낸다
    public func loadAndFetchUser() -> Observable<User> {
        guard let userId = userSession.userId else {
            return .error(DomainError.missingDomainSession)
        }

        return userFetcher(userId: userId)
            .fetch()
            .fetchedValues()
    }
}

// MARK: - Test
#if DEBUG
extension AuthUsecaseImpl {
    public func bootstrapUserSession(uid: String) -> Single<User> {
        repository.fetchUser(uid: uid) // Single<User?>
            .flatMap { user -> Single<User> in
                guard let user = user else {
                    return .error(DomainError.userNotFound)
                }
                return .just(user)
            }
            .do(onSuccess: { [weak self] user in
                self?.userSession.update(user)
            })
    }
}
#endif

// MARK: - Fetcher
private extension AuthUsecaseImpl {
    /// 유저 세션과 서버 유저를 맞추는 Fetcher
    /// - 서버에 유저가 없으면 유저·그룹 세션을 지운다. AppCoordinator가 로그인 화면으로 보낸다
    func userFetcher(userId: String) -> Fetcher<User> {
        let userSession = userSession
        let groupSession = groupSession
        let repository = repository

        return Fetcher(
            local: { userSession.session },
            observeLocal: { userSession.asObservable() },
            remote: { repository.fetchUser(uid: userId) },
            updateLocal: { user in
                userSession.update(user)
            },
            removeLocal: {
                groupSession.clear()
                userSession.clear()
            },
            // 이미 로그아웃했거나 다른 유저로 바뀐 뒤 늦게 온 응답은 버린다
            isCurrent: { userSession.userId == userId }
        )
        .timeout(.seconds(15))
        .sharing(userRequests, key: userId)
        .logging("User")
    }

    /// 서버에 쓴 뒤 서버 유저만 다시 받아 세션에 저장한다
    /// - 쓰기 전에 시작된 유저 요청에 합류하지 않으므로 다시 받은 유저에는 방금 쓴 내용이 들어 있다
    /// - 그사이 로그아웃했거나 다른 유저로 바뀌면 값 없이 끝나 에러가 된다
    func writeUserThenReload(
        userId: String,
        write: @escaping () -> Single<Void>
    ) -> Single<User> {
        userFetcher(userId: userId)
            .writeThenRefresh(write)
            .fetchedValues()
            .asSingle()
    }
}
