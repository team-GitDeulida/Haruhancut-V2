//
//  AuthUsecase.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import Foundation
import RxSwift
import Core

public protocol AuthUsecaseProtocol {
    func loginWithKakao() -> Observable<Result<String, LoginError>>
}

public final class AuthUsecaseImpl: AuthUsecaseProtocol {

    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return authRepository.loginWithKakao()
    }
}

public final class StubAuthUsecaseImpl: AuthUsecaseProtocol {
    
    public init() {}
    
    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return .just(.success("mockToken"))
    }
}
