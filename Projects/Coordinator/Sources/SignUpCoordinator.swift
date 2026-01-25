//
//  SignUpCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import Domain
import AuthFeature

public final class SignUpCoordinator: Coordinator {
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    private let navigationController: UINavigationController
    private let platform: User.LoginPlatform
    
    public init(
        navigationController: UINavigationController,
        platform: User.LoginPlatform
    ) {
        self.navigationController = navigationController
        self.platform = platform
    }
    
    public func start() {
        let builder = AuthFeatureBuilder()
        var signUp = builder.makeSignUp(platform: platform)
        
        signUp.vm.onSignUpSuccess = { [weak self] in
            guard let self = self else { return }
            
            // 회원가입 플로우 종료
            self.parentCoordinator?.childDidFinish(self)
        }
        
        self.navigationController.setViewControllers([signUp.vc], animated: true)
    }
}
