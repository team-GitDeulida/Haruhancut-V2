//
//  AuthRepositoryProtocol.swift
//  Domain
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import RxSwift
import Core

public protocol AuthRepositoryProtocol {
    // MARK: - Login
    func loginWithKakao() -> Single<String>
    func loginWithApple() -> Single<(String, String)>
    func authenticateUser(providerID: String, idToken: String, rawNonce: String?) -> Single<String>
    func reauthenticate(platform: User.LoginPlatform) -> Single<Void>
    func signOut() -> Single<Void>
    
    // MARK: - User
    func registerUserToRealtimeDatabase(user: User) -> Single<User>
    /// 유저를 조회합니다. 서버에 유저가 없으면 `nil`, 읽지 못하면 에러를 보냅니다.
    func fetchUser(uid: String) -> Single<User?>
    
    func updateUser(user: User) -> Single<User>
    func deleteAuthUser() -> Single<Void>
    func deleteDBUser(uid: String) -> Single<Void>
    func patchUser(uid: String, fields: [String: Any]) -> Single<Void>
    
    // MARK: - Image
    func uploadImage(user: User, image: UIImage) -> Single<URL>
    
    // MARK: - Fcm
    func generateFcmToken() -> Single<String>
}
