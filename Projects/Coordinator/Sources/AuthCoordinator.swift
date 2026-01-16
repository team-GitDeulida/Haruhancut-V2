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
    private let userSession: UserSessionType
    
    public init(
        navigationController: UINavigationController,
        userSession: UserSessionType
    ) {
        self.navigationController = navigationController
        self.userSession = userSession
    }
    
    public func start() {
        let builder = AuthFeatureBuilder()
        var signIn = builder.makeSignIn()
        
        // 기존 유저
        signIn.vm.onSignInSuccess = { [weak self] in
            guard let self = self else { return }
            
            // 로그인 성공시 세션 전달
            self.userSession.update(user: User.sampleUser1)
            
            // Auth 플로우 종료
            self.parentCoordinator?.childDidFinish(self)
        }
        
        // 회원가입
        signIn.vm.onFirstSignInSuccess = { [weak self] in
            guard let self = self else { return }
            
            // AuthCoordinator 종료
            self.parentCoordinator?.childDidFinish(self)
            
            // AppCoordinator에게 회원가입 플로우 요청
            (self.parentCoordinator as? AppCoordinator)?.startSignUpFlowCoordinator()
        }
        
        self.navigationController.setViewControllers([signIn.vc], animated: true)
    }
}
