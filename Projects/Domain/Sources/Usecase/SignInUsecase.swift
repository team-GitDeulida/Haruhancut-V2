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

}

public final class SignInUsecaseImpl: SignInUsecaseProtocol {

    private let signInRepository: SignInRepositoryProtocol
    
    public init(signInRepository: SignInRepositoryProtocol) {
        self.signInRepository = signInRepository
    }
}

public final class StubSignInUsecaseImpl: SignInUsecaseProtocol {
    
    public init() {}
    
}
