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
    func loginWithKakao() -> Observable<Result<String, LoginError>>
    func loginWithApple() -> Observable<Result<(String, String), LoginError>>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>>
    func fetchUserInfo() -> Observable<User?>
    func fetchUser(uid: String) -> Observable<User?>
    func updateUser(user: User) -> Observable<Result<User, LoginError>>
    func deleteUser(uid: String) -> Observable<Bool>
    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>>
}
