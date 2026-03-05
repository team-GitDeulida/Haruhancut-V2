//
//  OnboardingCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 3/5/26.
//

import UIKit
import OnboardingFeature

public final class OnboardingCoordinator: Coordinator {
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = OnboardingFeatureBuilder()
        var onboarding = builder.makeOnboarding()

        onboarding.vm.onEndButtonTapped = { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(true, forKey: "Tutorial")
            self.navigationController.dismiss(animated: false)
            (self.parentCoordinator as? AppCoordinator)?.startSessionFlow()
        }

        onboarding.vc.modalPresentationStyle = .fullScreen
        navigationController.present(onboarding.vc, animated: false)
    }
}
