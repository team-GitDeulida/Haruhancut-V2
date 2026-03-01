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

    func updateUser(user: User) -> Single<User>
    func uploadImage(user: User, image: UIImage) -> Single<URL>
    
    // MARK: - Sign
    func signIn(platform: User.LoginPlatform) -> Single<SignInResult>
    func signUp(user: User, profileImage: UIImage?) -> Single<Void>
    
    // MARK: - FCM
    func generateFcmToken() -> Single<String>
    func syncFcmIfNeeded() -> Single<Void>
    func loadAndFetchUser() -> Observable<User>

    // MARK: - Test
    func bootstrapUserSession(uid: String) -> Single<User>
}

public final class AuthUsecaseImpl: AuthUsecaseProtocol {

    private let repository: AuthRepositoryProtocol
    private let userSession: UserSession
    private let fcmTokenStore: FCMTokenStore
    
    public init(authRepository: AuthRepositoryProtocol,
                userSession: UserSession,
                fcmTokenStore: FCMTokenStore
    ) {
        self.repository = authRepository
        self.userSession = userSession
        self.fcmTokenStore = fcmTokenStore
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

// MARK: - Sign in / Sign Up
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
            .do(onSuccess: { savedUser in
                // 최종 유저를 세션에 저장
                self.userSession.update(savedUser)
            })
            .mapToVoid()
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
            .do { result in
                if case .existingUser(let user) = result {
                    Logger.d("기존 사용자")
                    self.userSession.update(user)
                }
            }
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
        
        // 로컬 최신 토큰 없으면 조기리턴
        guard let localToken = fcmTokenStore.latestToken else {
            return .just(())
        }
        
        return repository.fetchUser(uid: sessionUser.uid)
            .flatMap { serverUser -> Single<Void> in
                let serverToken = serverUser?.fcmToken
                
                // 값이 같으면 아무것도 안 함
                if serverToken == localToken {
                    return .just(())
                }
                
                // 다르면 patch
                return self.repository.patchUser(uid: sessionUser.uid,
                                            fields: ["fcmToken": localToken])
                .do(onSuccess: {
                    self.userSession.update(\.fcmToken, localToken)
                    Logger.d("FCM 토큰 동기화 완료")
                })
            }
    }
}

extension AuthUsecaseImpl {
    public func loadAndFetchUser() -> Observable<User> {
        guard let userId = userSession.userId else {
            return .error(DomainError.missingDomainSession)
        }
        
        // 1. 캐시에서 유저 가져옴
        let cached = userSession.session
            .map { Observable.just($0) } ?? .empty()
        
        // 2. 서버에서 유저 가져옴
        let remote = repository.fetchUser(uid: userId)
            .compactMap { $0 } // nil 제거(PrimitiveSequence<MaybeTrait, User>)
            .asObservable()
            .do(onNext: { user in
                self.userSession.update(user)
            })

        // 3. 캐시 -> 서버 순서로 방출
        return Observable.concat(cached, remote)
            .enumerated()
            .do(onNext: { index, user in
                Logger.d("\n[\(index)]번째 방출: \(user.description)")
            })
            .map { $0.element }
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
