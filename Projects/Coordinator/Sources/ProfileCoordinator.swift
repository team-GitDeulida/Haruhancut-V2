//
//  ProfileCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 2/9/26.
//

import Domain
import ProfileFeature
import UIKit

public final class ProfileCoordinator: Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = ProfileFeatureBuilder()
        let profile = builder.makeProfile()
        
        profile.vc.onPop = { [weak self] in
            guard let self else { return }
            self.parentCoordinator?.childDidFinish(self)
        }
        
        navigationController.pushViewController(profile.vc, animated: true)
    }
}
