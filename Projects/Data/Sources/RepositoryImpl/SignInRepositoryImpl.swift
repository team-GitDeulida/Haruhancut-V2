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
public final class SignInRepositoryImpl: SignInRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    private let appleLoginManager: AppleLoginManagerProtocol
    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    private let firebaseStorageManager: FirebaseStorageManagerProtocol
    
    private let userSession: UserSessionType
    
    public init(
        kakaoLoginManager: KakaoLoginManagerProtocol,
        appleLoginManager: AppleLoginManagerProtocol,
        firebaseAuthManager: FirebaseAuthManagerProtocol,
        firebaseStorageManager: FirebaseStorageManagerProtocol,
        userSession: UserSessionType
    ) {
        self.kakaoLoginManager = kakaoLoginManager
        self.appleLoginManager = appleLoginManager
        self.firebaseAuthManager = firebaseAuthManager
        self.firebaseStorageManager = firebaseStorageManager
        self.userSession = userSession
    }
    
    public func loginWithKakao() -> Single<String> {
        return kakaoLoginManager.login()
    }
    
    public func loginWithApple() -> Single<(String, String)> {
        return appleLoginManager.login()
    }
    
    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Single<Void> {
        return firebaseAuthManager.authenticateUser(prividerID: prividerID,
                                                    idToken: idToken,
                                                    rawNonce: rawNonce)
    }
    
    public func registerUserToRealtimeDatabase(user: User) -> Single<User> {
        return firebaseAuthManager
            .registerUserToRealtimeDatabase(user: user)
            .do(onSuccess: { user in
                self.userSession.update(SessionUser(userId: user.uid,
                                                    groupId: nil)) // 사용자 생성 시 그룹Id 없음
            })
    }
    
    public func fetchMyUser() -> Single<User> {
        
        /*
        // 캐시 먼저 방출
        let cached = Observable.just(userSession.sessionUser)
        
        // 서버 데이터 방출
        let remote = firebaseAuthManager.fetchMyInfo()
            .do(onNext: { [weak self] user in
                guard let self, let user = user else { return }
                
                // 서버 데이터 session 업데이트
                self.userSession.update(SessionUser(userId: user.uid))
            })
        
        return Observable.concat(.just(nil), remote)
         */
        
        return firebaseAuthManager.fetchMyInfo()
            .flatMap { userOptional in
                guard let user = userOptional else {
                    return .error(LoginError.noUser)
                }
                self.userSession.update(SessionUser(userId: user.uid, groupId: user.groupId))
                return .just(user)
            }
    }
    
    public func fetchUser(uid: String) -> Single<User> {
        return firebaseAuthManager.fetchUser(uid: uid)
            .flatMap { userOptional in
                guard let user = userOptional else {
                    return .error(LoginError.noUser)
                }
                return .just(user)
            }
    }
    
    public func updateUser(user: User) -> Single<User> {
        return firebaseAuthManager.updateUser(user: user)
            .map { user } // 의도: updateUser는 성공시 Void이지만 매개변수를 다시 반환 용도
            // MARK:  인프라로 변환 안함 .catch { _ in return .error(LoginError.updateUserError) }
    }
    
    public func deleteUser(uid: String) -> Single<Void> {
        return firebaseAuthManager.deleteUser(uid: uid)
            .do(onSuccess: { [weak self] in
                self?.userSession.clear()
            })
            .map { () }
    }
    
    public func uploadImage(user: User, image: UIImage) -> Single<URL> {
        let path = "users/\(user.uid)/profile.jpg"
        return firebaseStorageManager.uploadImage(image: image, path: path)
    }
}
