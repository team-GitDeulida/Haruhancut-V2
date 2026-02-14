//
//  CameraCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 2/13/26.
//

import UIKit

public final class CameraCoordinator: Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        
    }
}
