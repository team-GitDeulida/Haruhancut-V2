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
    // func fetchUserInfo() -> Single<User>
    func updateUser(user: User) -> Single<User>
    func uploadImage(user: User, image: UIImage) -> Single<URL>
    
    // MARK: - Sign
    func signIn(platform: User.LoginPlatform) -> Single<SignInResult>
    func signUp(user: User, profileImage: UIImage?) -> Single<Void>
}

public final class AuthUsecaseImpl: AuthUsecaseProtocol {

    private let repository: AuthRepositoryProtocol
    private let userSession: UserSessionType
    
    public init(authRepository: AuthRepositoryProtocol,
                userSession: UserSessionType
    ) {
        self.repository = authRepository
        self.userSession = userSession
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
    
    public func signUp(user: User, profileImage: UIImage?) -> Single<Void> {
        repository.registerUserToRealtimeDatabase(user: user)
            .flatMap { registeredUser in
                guard let image = profileImage else {
                    // 이미지가 없다면 바로 성공(Void) 반환
                    return .just(())
                }

                return self.uploadImage(user: registeredUser, image: image)
                    .flatMap { url in
                        var updated = registeredUser
                        updated.profileImageURL = url.absoluteString
                        return self.updateUser(user: updated)
                            .mapToVoid()
                    }
                    .do(onSuccess: {
                        self.userSession.update(SessionUser(userId: user.uid,
                                                            groupId: nil,
                                                            nickname: user.nickname,
                                                            proprofileImageURL: user.profileImageURL))
                       //  self.userSession.update(\.userId, registeredUser.uid)
                    })
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
            .do { result in
                if case .existingUser(let user) = result {
                    Logger.d("기존 사용자")
                    self.userSession.update(SessionUser(userId: user.uid,
                                                        groupId: user.groupId,
                                                        nickname: user.nickname,
                                                        proprofileImageURL: user.profileImageURL))
                }
            }
    }
}

// MARK: - Sign in
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
