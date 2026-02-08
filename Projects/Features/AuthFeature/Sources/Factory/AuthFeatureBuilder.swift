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
    
    func makeGroup() -> GroupPresentable
}

// MARK: - Builder
public final class AuthFeatureBuilder {
    
    public init() {}
    
}

extension AuthFeatureBuilder: AuthFeatureBuildable {
    
    public func makeSignIn() -> SignInPresentable {
        @Dependency var authUsecase: AuthUsecaseProtocol
        let vm = SignInViewModel(authUsecase: authUsecase)
        let vc = SignInViewController(signInViewModel: vm)
        return (vc, vm)
    }
    
    public func makeSignUp(platform: User.LoginPlatform) -> SignUpPresentable {
        // @Dependency var signUpUsecase: SignUpUsecaseProtocol
        // let vm = SignUpViewModel(signUpUsecase: signUpUsecase)
        @Dependency var authUsecase: AuthUsecaseProtocol
        let vm = SignUpViewModel(authUsecase: authUsecase, loginPlatform: platform)
        let vc = SignUpViewController(viewModel: vm)
        return (vc, vm)
    }
    
    public func makeGroup() -> GroupPresentable {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = GroupViewModel(groupUsecase: groupUsecase)
        let vc = GroupViewController(viewModel: vm)
        return (vc, vm)
    }
}
