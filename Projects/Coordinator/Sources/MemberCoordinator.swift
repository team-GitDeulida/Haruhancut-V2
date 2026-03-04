//
//  MemberCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import MemberFeature

public final class MemberCoordinator: Coordinator {
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = MemberFeatureBuilder()
        let member = builder.makeMember()
        
        navigationController.pushViewController(member.vc, animated: true)
    }
}
