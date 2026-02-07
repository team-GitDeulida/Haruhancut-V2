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

public protocol SignInUsecaseProtocol {
    func signIn(with platform: User.LoginPlatform) -> Single<SocialAuthPayload>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Single<Void>
    func registerUserToRealtimeDatabase(user: User) -> Single<User>
    func fetchUserInfo() -> Single<User>
    func updateUser(user: User) -> Single<User>
    func uploadImage(user: User, image: UIImage) -> Single<URL>
    
    // 일단 임시로 signup을 여기구현
    func signUp(user: User, profileImage: UIImage?) -> Single<Void>
}

public final class SignInUsecaseImpl: SignInUsecaseProtocol {

    private let repository: SignInRepositoryProtocol
    
    public init(signInRepository: SignInRepositoryProtocol) {
        self.repository = signInRepository
    }
    
    public func signIn(with platform: User.LoginPlatform) -> Single<SocialAuthPayload> {
        switch platform {
        case .kakao:
            return repository.loginWithKakao() // Single<String>
                .map { SocialAuthPayload.kakao(token: $0) }
        case .apple: // Observable<Result<(String, String), LoginError>>
            return repository.loginWithApple()
                .map { SocialAuthPayload.apple(idToken: $0.0, rawNonce: $0.1) }
        }
    }
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Single<Void> {
        return repository.authenticateUser(prividerID: prividerID, idToken: idToken, rawNonce: rawNonce)
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    public func registerUserToRealtimeDatabase(user: User) -> Single<User> {
        return repository.registerUserToRealtimeDatabase(user: user)
    }
    
    /// 본인 정보 불러오기
    /// - Returns: Observable<User?>
    public func fetchUserInfo() -> Single<User> {
        return repository.fetchMyUser()
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
        registerUserToRealtimeDatabase(user: user)
            .flatMap { registeredUser in
                guard let image = profileImage else {
                    return .just(registeredUser)
                }

                return self.uploadImage(user: registeredUser, image: image)
                    .flatMap { url in
                        var updated = registeredUser
                        updated.profileImageURL = url.absoluteString
                        return self.updateUser(user: updated)
                    }
            }
            .map { _ in () }
    }

}
