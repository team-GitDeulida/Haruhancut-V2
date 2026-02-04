//
//  AuthUsecase.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import Foundation
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

    func signIn(with: User.LoginPlatform) -> Observable<Result<SocialAuthPayload, LoginError>>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>>
    func fetchUserInfo() -> Observable<Result<User, LoginError>>
    func updateUser(user: User) -> Observable<Result<User, LoginError>>
    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>>
}

public final class SignInUsecaseImpl: SignInUsecaseProtocol {

    private let repository: SignInRepositoryProtocol
    
    public init(signInRepository: SignInRepositoryProtocol) {
        self.repository = signInRepository
    }
    
    public func signIn(with platform: User.LoginPlatform) -> Observable<Result<SocialAuthPayload, LoginError>> {
        switch platform {
        case .kakao: // Observable<Result<String, LoginError>>
            return repository.loginWithKakao()
                .map { result in
                    result.map { token in // result: Result<String, LoginError>
                        .kakao(token: token)
                    }
                }
        case .apple: // Observable<Result<(String, String), LoginError>>
            return repository.loginWithApple()
                .map { $0.map(SocialAuthPayload.apple) }
        }
    }
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        return repository.authenticateUser(prividerID: prividerID, idToken: idToken, rawNonce: rawNonce)
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    public func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
        return repository.registerUserToRealtimeDatabase(user: user)
    }
    
    /// 본인 정보 불러오기
    /// - Returns: Observable<User?>
    public func fetchUserInfo() -> Observable<Result<User, LoginError>> {
        return repository.fetchMyUser()
    }
    
    /// 유저 업데이트
    /// - Parameter user: 유저
    /// - Returns: 성공유무
    public func updateUser(user: User) -> Observable<Result<User, LoginError>> {
        return repository.updateUser(user: user)
    }
    
    /// 이미지 업로드
    /// - Parameters:
    ///   - user: 유저
    ///   - image: 이미지
    /// - Returns: 이미지url
    public func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>> {
        return repository.uploadImage(user: user, image: image)
    }
    
    
}

/*
public final class StubSignInUsecaseImpl: SignInUsecaseProtocol {
    
    public init() {}
    
    public func signIn(with platform: User.LoginPlatform) -> Observable<Result<Void, LoginError>> {
        switch platform {
        case .kakao:
            // 임시 기존 유저
            return .just(Result.success(()))
        case .apple:
            return.just(.failure(.noUser))
        }
    }
    
    public func signInKakao(with: User.LoginPlatform) -> RxSwift.Observable<Result<String, LoginError>> {
        .just(.success(""))
    }
    
    /*
    public func signIn(with: User.LoginPlatform) -> Observable<Result<Void, LoginError>> {
        return .just(Result.success(()))
    }
     */
}
*/

