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
    func loginWithKakao() -> Observable<Result<String, LoginError>>
    func loginWithApple() -> Observable<Result<(String, String), LoginError>>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    
    // MARK: - User
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
    func fetchMyUser() -> Observable<Result<User, LoginError>>
    func fetchUser(uid: String) -> Observable<Result<User, LoginError>>
    
    func updateUser(user: User) -> Observable<Result<User, LoginError>>
    func deleteUser(uid: String) -> Observable<Result<Void, LoginError>>
    
    // MARK: - Image
    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>>
}
