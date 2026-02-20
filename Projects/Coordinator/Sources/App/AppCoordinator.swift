//
//  AppCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 
//

import UIKit
import Domain
import Core
//import Data
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
    @Dependency var userSession: UserSession
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // 로그인플로우 or 홈 플로우
    public func start() {
        observeSession()
        routeBySession()
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
    
    // 그룹 플로우
    func startGroupFlowCoordinator() {
        if childCoordinators.contains(where: { $0 is GroupCoordinator }) {
            return
        }
        
        let coordinator = GroupCoordinator(navigationController: navigationController)
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    // 로그아웃
    func logoutWithRotation() {
        // 회전 애니메이션으로 로그인 플로우 시작
        UIView.transition(
            with: navigationController.view,
            duration: 0.4,
            options: .transitionFlipFromLeft,
            animations: {
                // 로그아웃
                try? Auth.auth().signOut()
                
                // 세션 정리 (상태 변경)
                self.userSession.clear()
            }
        )
    }
}

private extension AppCoordinator {
    
    // MARK: - Root Flow
    // 앱 최초 실행 시 진입할 플로우를 결정한다
    func routeBySession() {
        let isLoggedIn =
        userSession.hasSession &&
        Auth.auth().currentUser != nil
        
        // 1️⃣ 로그인 안 됨
        guard isLoggedIn else {
            startLoginFlowCoordinator()
            return
        }

        // 2️⃣ 로그인 됐는데 그룹 없음
        guard userSession.hasGroup else {
            startGroupFlowCoordinator()
            print("그룹 플로우")
            return
        }

        // 3️⃣ 로그인 + 그룹 있음
        startHomeFlowCoordinator()
    }
    
    // MARK: - Bind Session
    // 로그인 / 로그아웃 등 앱 실행 중 발생하는 상태 변화에 반응한다
    func observeSession() {
        userSession.observe { [weak self] (user: SessionUser?) in
            guard let self = self else { return }
            self.routeBySession()
        }
    }
}
