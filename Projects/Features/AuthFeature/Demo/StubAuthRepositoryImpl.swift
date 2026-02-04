//
//  StubAuthRepositoryImpl.swift
//  AuthFeatureDemo
//
//  Created by 김동현 on 1/13/26.
//

import Domain
import RxSwift
import Core

//public final class StubSignInRepositoryImpl: SignInRepositoryProtocol {
//    public func loginWithApple() -> RxSwift.Observable<Result<(String, String), Core.LoginError>> {
//        <#code#>
//    }
//    
//    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> RxSwift.Observable<Result<Void, Core.LoginError>> {
//        <#code#>
//    }
//    
//    public func registerUserToRealtimeDatabase(user: Domain.User) -> RxSwift.Observable<Result<Domain.User, Core.LoginError>> {
//        <#code#>
//    }
//    
//    public func fetchUserInfo() -> RxSwift.Observable<Domain.User?> {
//        <#code#>
//    }
//    
//    public func fetchUser(uid: String) -> RxSwift.Observable<Domain.User?> {
//        <#code#>
//    }
//    
//    public func updateUser(user: Domain.User) -> RxSwift.Observable<Result<Domain.User, Core.LoginError>> {
//        <#code#>
//    }
//    
//    public func deleteUser(uid: String) -> RxSwift.Observable<Bool> {
//        <#code#>
//    }
//    
//    public func uploadImage(user: Domain.User, image: UIImage) -> RxSwift.Observable<Result<URL, Core.LoginError>> {
//        <#code#>
//    }
//    
//    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
//        return .just(.success("mockToken"))
//    }
//}
