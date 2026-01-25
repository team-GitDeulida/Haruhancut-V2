//
//  AppCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 
//

import UIKit
import Domain
import Core
import Data
import FirebaseAuth

public protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get set }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

extension Coordinator {
    func childDidFinish(_ child: Coordinator?) {
        guard let child = child else { return }
        childCoordinators.removeAll() { $0 === child }
    }
}

public final class AppCoordinator: Coordinator {

    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    public var navigationController: UINavigationController
    @Dependency private var userSession: UserSessionType
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // 로그인플로우 or 홈 플로우
    public func start() {
        routeInitialFlow()
        bindUserSession()
    }
    
    // 로그인 플로우
    func startLoginFlowCoordinator() {
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator.parentCoordinator = self
        childCoordinators.append(authCoordinator)
        authCoordinator.start()
    }
    
    // 홈 플로우
    func startHomeFlowCoordinator() {
        // print("홈 플로우 실행 예정")
        
        // 1. AuthCoordinator 제거
        childCoordinators.removeAll { $0 is AuthCoordinator }
        
        // 2. HomeCoordinator 중복 방지
        if childCoordinators.contains(where: { $0 is HomeCoordinator }) {
            return
        }
        
        // 3 HomeCoordinator 시작
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        homeCoordinator.parentCoordinator = self
        childCoordinators.append(homeCoordinator)
        homeCoordinator.start()
    }
    
    // 회원가입 플로우
    func startSignUpFlowCoordinator(platform: Domain.User.LoginPlatform) {
        // 1. 중복 방지
        if childCoordinators.contains(where: { $0 is SignUpCoordinator }) {
            return
        }
        
        // 2. SignUpCoordinator 생성
        let signUpCoordinator = SignUpCoordinator(navigationController: navigationController,
                                           
                                                  platform: platform)
        
        signUpCoordinator.parentCoordinator = self
        childCoordinators.append(signUpCoordinator)
        signUpCoordinator.start()
    }
}

private extension AppCoordinator {
    
    // 앱 최초 실행 시 진입할 플로우를 결정한다
    func routeInitialFlow() {
        let isLoggedIn =
        // userSession.isLoggedIn &&
        Auth.auth().currentUser != nil
    
        if isLoggedIn {
            // 앱 시작 시 이미 로그인된 유저가 있음 → 홈 플로우
            startHomeFlowCoordinator()
        } else {
            // 앱 시작 시 로그인된 유저가 없음 → 로그인 플로우
            startLoginFlowCoordinator()
        }
    }
    
    // 로그인 / 로그아웃 등 **앱 실행 중 발생하는 상태 변화**에 반응한다
    func bindUserSession() {
        userSession.bind { [weak self] (user: SessionUser?) in
            guard let self = self else { return }
            
            if user == nil {
                self.startLoginFlowCoordinator()
            } else {
                self.startHomeFlowCoordinator()
            }
        }
    }
}
