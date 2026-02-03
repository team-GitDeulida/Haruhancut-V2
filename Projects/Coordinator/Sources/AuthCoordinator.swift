//
//  AuthCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 1/13/26.
//

import UIKit
import Domain
import AuthFeature

public final class AuthCoordinator: Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = AuthFeatureBuilder()
        var signIn = builder.makeSignIn()
        
        // 기존 유저
        signIn.vm.onSignInSuccess = { [weak self] in
            guard let self = self else { return }
            
            // Auth 플로우 종료
            self.parentCoordinator?.childDidFinish(self)
        }
        
        // 회원가입
        signIn.vm.onFirstSignInSuccess = { [weak self] platform in
            guard let self = self else { return }
            
            // AuthCoordinator 종료
            self.parentCoordinator?.childDidFinish(self)
            
            // AppCoordinator에게 회원가입 플로우 요청
            (self.parentCoordinator as? AppCoordinator)?.startSignUpFlowCoordinator(platform: platform)
        }
        
        self.navigationController.setViewControllers([signIn.vc], animated: true)
    }
}
