//
//  GroupCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import AuthFeature

public final class GroupCoordinator: Coordinator {
    
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
        var group = builder.makeGroup()
        
        // 그룹 생성 or 참여 완료 시
        group.vm.onGroupMakeOrJoinSuccess = { [weak self] in
            guard let self = self else { return }
            
            // GroupCoordinator 종료
            self.parentCoordinator?.childDidFinish(self)
            
            // AppCoordinator에게 홈 플로우 요청
            (self.parentCoordinator as? AppCoordinator)?.startHomeFlowCoordinator()
        }
        
        navigationController.setViewControllers([group.vc], animated: true)
    }
}
