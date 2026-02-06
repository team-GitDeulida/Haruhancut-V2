//
//  AuthRepositoryProtocol.swift
//  Domain
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import RxSwift
import Core

public protocol SignInRepositoryProtocol {
    // MARK: - Login
    func loginWithKakao() -> Single<String>
    func loginWithApple() -> Single<(String, String)>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Single<Void>
    
    // MARK: - User
    func registerUserToRealtimeDatabase(user: User) -> Single<User>
    func fetchMyUser() -> Single<User>
    func fetchUser(uid: String) -> Single<User>
    
    func updateUser(user: User) -> Single<User>
    func deleteUser(uid: String) -> Single<Void>
    
    // MARK: - Image
    func uploadImage(user: User, image: UIImage) -> Single<URL>
}
