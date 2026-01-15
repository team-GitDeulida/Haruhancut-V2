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
    private let userSession: UserSessionType
    
    public init(
        navigationController: UINavigationController,
        userSession: UserSessionType
    ) {
        self.navigationController = navigationController
        self.userSession = userSession
    }
    
    public func start() {
        let builder = HomeFeatureBuilder()
        let home = builder.makeHome()
        
        // 홈은 루트 플로우 → 스택 교체
        navigationController.setViewControllers([home.vc], animated: true)
    }
}
