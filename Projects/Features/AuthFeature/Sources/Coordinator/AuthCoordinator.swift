//
//  AuthCoordinator.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit

final class AuthCoordinator {

    private let navigation: UINavigationController
    private let factory: AuthFeatureBuildable

    init(navigation: UINavigationController,
         factory: AuthFeatureBuildable) {
        self.navigation = navigation
        self.factory = factory
    }

    func start() {
        var feature = factory.makeSignIn()

        feature.vm.onAuthCompleted = {
            print("✅ Auth Flow Finished")
        }

        navigation.pushViewController(
            feature.vc,
            animated: true
        )
    }
}

