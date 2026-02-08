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

/*
 값 그대로 + 부수효과 → do
 값 변환 → map
 값에 따라 성공/실패 결정 → flatMap
 에러 변환 → catch
 */
public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    
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
    
    public func loginWithKakao() -> Single<String> {
        return kakaoLoginManager.login()
    }
    
    public func loginWithApple() -> Single<(String, String)> {
        return appleLoginManager.login()
    }
    
    public func authenticateUser(providerID: String, idToken: String, rawNonce: String?) -> Single<String> {
        return firebaseAuthManager.authenticateUser(providerID: providerID,
                                                    idToken: idToken,
                                                    rawNonce: rawNonce)
    }
    
    public func registerUserToRealtimeDatabase(user: User) -> Single<User> {
        return firebaseAuthManager
            .registerUserToRealtimeDatabase(user: user)
    }
    
    public func fetchUser(uid: String) -> Single<User?> {
        return firebaseAuthManager.fetchUser(uid: uid)
            .catch { error in
                if case LoginError.noUser = error {
                    return .just(nil)
                }
                return .error(error)
            }
    }
    
    public func updateUser(user: User) -> Single<User> {
        return firebaseAuthManager.updateUser(user: user)
            .map { user } // 의도: updateUser는 성공시 Void이지만 매개변수를 다시 반환 용도
            // MARK:  인프라로 변환 안함 .catch { _ in return .error(LoginError.updateUserError) }
    }
    
    public func deleteUser(uid: String) -> Single<Void> {
        return firebaseAuthManager.deleteUser(uid: uid)
//            .do(onSuccess: { [weak self] in
//                self?.userSession.clear()
//            })
            .map { () }
    }
    
    public func uploadImage(user: User, image: UIImage) -> Single<URL> {
        let path = "users/\(user.uid)/profile.jpg"
        return firebaseStorageManager.uploadImage(image: image, path: path)
    }
}
