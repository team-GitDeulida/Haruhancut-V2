//
//  AuthUsecase.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import Foundation
import RxSwift
import Core

public protocol SignInUsecaseProtocol {
    func signIn(with: User.LoginPlatform) -> Observable<Result<Void, LoginError>>
}

public final class SignInUsecaseImpl: SignInUsecaseProtocol {

    private let signInRepository: SignInRepositoryProtocol
    
    public init(signInRepository: SignInRepositoryProtocol) {
        self.signInRepository = signInRepository
    }
    
    public func signIn(with platform: User.LoginPlatform) -> Observable<Result<Void, LoginError>> {
        switch platform {
        case .kakao:
            // 임시 기존 유저
            return .just(Result.success(()))
        case .apple:
            return.just(.failure(.noUser))
        }
    }
}

public final class StubSignInUsecaseImpl: SignInUsecaseProtocol {
    
    public init() {}
    
    public func signIn(with: User.LoginPlatform) -> Observable<Result<Void, LoginError>> {
        return .just(Result.success(()))
    }
}
