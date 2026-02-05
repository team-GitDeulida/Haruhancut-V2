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

//public protocol SignInRepositoryProtocol {
//    // MARK: - Login
//    func loginWithKakao() -> Observable<Result<String, LoginError>>
//    func loginWithApple() -> Observable<Result<(String, String), LoginError>>
//    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
//    
//    // MARK: - User
//    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
//    func fetchMyUser() -> Observable<Result<User, LoginError>>
//    func fetchUser(uid: String) -> Observable<Result<User, LoginError>>
//    
//    func updateUser(user: User) -> Observable<Result<User, LoginError>>
//    func deleteUser(uid: String) -> Observable<Result<Void, LoginError>>
//    
//    // MARK: - Image
//    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>>
//}


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
    
    public func loginWithKakao() -> RxSwift.Observable<Result<String, LoginError>> {
        kakaoLoginManager.login()
    }
    
    public func loginWithApple() -> RxSwift.Observable<Result<(String, String), LoginError>> {
        appleLoginManager.login()
    }
    
    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        return firebaseAuthManager.authenticateUser(prividerID: prividerID,
                                                    idToken: idToken,
                                                    rawNonce: rawNonce)
        /*
        .map { .success(()) }
        .catch { _ in
            .just(.failure(.authError))
        }
         */
        .asResult(failure: .authError)
    }
    
    public func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
        return firebaseAuthManager
            .registerUserToRealtimeDatabase(user: user)
            .map { user in
                self.userSession.update(
                    SessionUser(userId: user.uid, groupId: user.groupId)
                )
                return .success(user)
            }
            .catch { _ in
                .just(.failure(.signUpError))
            }
    }
    
    public func fetchMyUser() -> Observable<Result<User, LoginError>> {
        
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
            .map { userOptional in
                guard let user = userOptional else {
                    return .failure(.noUser)
                }
                
                self.userSession.update(SessionUser(userId: user.uid, groupId: user.groupId))
                return .success(user)
            }
            .catch { _ in
                .just(.failure(.fetchUserError))
            }
    }
    
    public func fetchUser(uid: String) -> Observable<Result<User, LoginError>> {
        return firebaseAuthManager.fetchUser(uid: uid)
            .map { userOptional in
                guard let user = userOptional else {
                    return .failure(.noUser)
                }
                return .success(user)
            }
            .catch { _ in
                .just(.failure(.fetchUserError))
            }
    }
    
    public func updateUser(user: User) -> Observable<Result<User, LoginError>> {
        return firebaseAuthManager.updateUser(user: user)
            .map { .success(user) }
            .catch { _ in
                .just(.failure(.updateUserError))
            }
    }
    
    public func deleteUser(uid: String) -> Observable<Result<Void, LoginError>> {
        return firebaseAuthManager.deleteUser(uid: uid)
            .do(onNext: { [weak self] in
                self?.userSession.clear()
            })
            .map { .success(()) }
            .catch { _ in .just(.failure(.deleteUserError)) }
    }
    
    public func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>> {
        
        let path = "users/\(user.uid)/profile.jpg"
        return firebaseStorageManager.uploadImage(image: image, path: path)
            .map { .success($0)}
            .catch { _ in .just(.failure(.uploadImageError)) }
    }
}
