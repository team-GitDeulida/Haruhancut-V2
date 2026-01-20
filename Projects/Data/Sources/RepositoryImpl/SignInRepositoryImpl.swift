//
//  AuthRepositoryImpl.swift
//  Domain
//
//  Created by 김동현 on 1/12/26.
//

import Domain
import RxSwift
import Core
import UIKit

public final class SignInRepositoryImpl: SignInRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    private let appleLoginManager: AppleLoginManagerProtocol
    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    private let firebaseStorageManager: FirebaseStorageManagerProtocol
    
    public init(
        kakaoLoginManager: KakaoLoginManagerProtocol,
        appleLoginManager: AppleLoginManagerProtocol,
        firebaseAuthManager: FirebaseAuthManagerProtocol,
        firebaseStorageManager: FirebaseStorageManagerProtocol
    ) {
        self.kakaoLoginManager = kakaoLoginManager
        self.appleLoginManager = appleLoginManager
        self.firebaseAuthManager = firebaseAuthManager
        self.firebaseStorageManager = firebaseStorageManager
    }
    
    public func loginWithKakao() -> RxSwift.Observable<Result<String, LoginError>> {
        kakaoLoginManager.login()
    }
    
    public func loginWithApple() -> RxSwift.Observable<Result<(String, String), LoginError>> {
        appleLoginManager.login()
    }
    
    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> RxSwift.Observable<Result<Void, LoginError>> {
        return firebaseAuthManager.authenticateUser(prividerID: prividerID, idToken: idToken, rawNonce: rawNonce)
    }
    
    public func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return firebaseAuthManager.registerUserToRealtimeDatabase(user: user)
    }
    
    public func fetchUserInfo() -> RxSwift.Observable<User?> {
        return firebaseAuthManager.fetchMyInfo()
    }
    
    public func fetchUser(uid: String) -> RxSwift.Observable<User?> {
        return firebaseAuthManager.fetchUser(uid: uid)
    }
    
    public func updateUser(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return firebaseAuthManager.updateUser(user: user)
    }
    
    public func deleteUser(uid: String) -> RxSwift.Observable<Bool> {
        return firebaseAuthManager.deleteUser(uid: uid)
    }
    
    public func uploadImage(user: User, image: UIImage) -> RxSwift.Observable<Result<URL, LoginError>> {
       
        let path = "users/\(user.uid)/profile.jpg"
        return firebaseStorageManager.uploadImage(image: image, path: path)
            .map { url in
                if let url = url {
                    return .success(url)
                } else {
                    return .failure(.signUpError)
                }
            }
    }
}

//public final class StubSignInRepositoryImpl: SignInRepositoryProtocol {
//    
//    public init() {}
//    
//    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
//        return .just(.success("mockToken"))
//    }
//}
