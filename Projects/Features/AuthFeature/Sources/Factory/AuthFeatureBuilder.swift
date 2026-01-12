//
//  AuthFeatureBuilder.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface

// MARK: - Creator(Factory Interface)
protocol AuthFeatureBuildable {
    func makeSignIn() -> SignInPresentable
}

// MARK: - Concrete Creator
final class AuthFeatureBuilder: AuthFeatureBuildable {
    
    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func makeSignIn() -> SignInPresentable {
        
        // Domain
        // let repository = AuthRepository()
        let useCase = AuthUseCase(repository: authRepository)
        let viewModel = AuthViewModel(useCase: useCase)
        
        // Scene
        let viewController = SignInViewController(viewModel: viewModel)
        
        // Concrete Product
        return (
            vc: viewController,
            vm: viewModel
        )
    }
}
