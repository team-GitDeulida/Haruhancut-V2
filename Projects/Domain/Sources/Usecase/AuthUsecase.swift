//
//  AuthUsecase.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import Foundation

public protocol AuthUsecaseProtocol {
    func signIn() async throws
}

public final class AuthUsecaseImpl: AuthUsecaseProtocol {
    
    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    public func signIn() async throws {
        
    }
}
