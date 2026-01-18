//
//  AuthFeatureBuilder.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import AuthFeatureInterface
import Core
import Domain

// MARK: - Buildable
public protocol AuthFeatureBuildable {
    
    /// Product 반환
    /// - Returns: Product
    func makeSignIn() -> SignInPresentable
    
    func makeSignUp(platform: User.LoginPlatform) -> SignUpPresentable
    
}

// MARK: - Builder
public final class AuthFeatureBuilder {
    
    public init() {}
    
}

extension AuthFeatureBuilder: AuthFeatureBuildable {
    
    public func makeSignIn() -> SignInPresentable {
        @Dependency var signInUsecase: SignInUsecaseProtocol
        let vm = SignInViewModel(signInUsecase: signInUsecase)
        let vc = SignInViewController(signInViewModel: vm)
        return (vc, vm)
    }
    
    public func makeSignUp(platform: User.LoginPlatform) -> SignUpPresentable {
        // @Dependency var signUpUsecase: SignUpUsecaseProtocol
        // let vm = SignUpViewModel(signUpUsecase: signUpUsecase)
        let vm = SignUpViewModel(loginPlatform: platform)
        let vc = SignUpViewController(viewModel: vm)
        return (vc, vm)
    }
}
