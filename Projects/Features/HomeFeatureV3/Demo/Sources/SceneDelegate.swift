//
//  SceneDelegate.swift
//  HomeFeatureV3Demo
//
//  Created by 김동현 on 7/27/26.
//

import HomeFeatureV3
import UIKit

final class SceneDelegate:
    UIResponder,
    UIWindowSceneDelegate
{
    var window: UIWindow?

    private var homeRouter:
        DemoHomeRouter?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions:
            UIScene.ConnectionOptions
    ) {
        guard
            let windowScene =
                scene as? UIWindowScene
        else {
            return
        }

        let navigationController =
            UINavigationController()
        let router = DemoHomeRouter(
            navigationController:
                navigationController
        )
        let homeViewController =
            HomeFeatureBuilder().makeHome(
                routeTrigger: router
            )

        router.attachNavigationItems(
            to: homeViewController
        )
        navigationController.setViewControllers(
            [homeViewController],
            animated: false
        )

        let window = UIWindow(
            windowScene: windowScene
        )
        window.rootViewController =
            navigationController
        window.makeKeyAndVisible()

        homeRouter = router
        self.window = window
    }
}
