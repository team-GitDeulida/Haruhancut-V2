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
        return (vc: vc, vm: vm)
    }
    
}
