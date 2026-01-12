//
//  AuthFeatureBuilder.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import Domain
import Core

// MARK: - Creator(Factory Interface)
public protocol AuthFeatureBuildable {
    func makeSignIn() -> SignInPresentable
}

// MARK: - Concrete Creator
public final class AuthFeatureBuilder: AuthFeatureBuildable {
    
    public init() {}
    
    public func makeSignIn() -> SignInPresentable {
        
        // Domain
        @Dependency var authUsecase: AuthUsecaseProtocol
        
        // ViewModel
        let viewModel = AuthViewModel(useCase: authUsecase)
        
        // Scene
        let viewController = SignInViewController(viewModel: viewModel)
        
        // Concrete Product
        return (
            vc: viewController,
            vm: viewModel
        )
    }
}
