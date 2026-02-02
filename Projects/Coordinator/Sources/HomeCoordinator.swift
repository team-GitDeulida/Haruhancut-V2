//
//  HomeCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 1/16/26.
//

import Domain
import HomeFeature
import UIKit

public final class HomeCoordinator: Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = HomeFeatureBuilder()
        var home = builder.makeHome()
        
        home.vm.onLogoutTapped = { [weak self] in
            guard let self = self else { return }
            
            // 로그인 화면으로 이동
            (self.parentCoordinator as? AppCoordinator)?
                .logoutWithRotation()
                //.userSession
                // .clear()
            
            // HomeCoordinator 종료
            self.parentCoordinator?.childDidFinish(self)
        }
        
        // 홈은 루트 플로우 → 스택 교체
        navigationController.setViewControllers([home.vc], animated: true)
    }
}
