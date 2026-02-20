//
//  SceneDelegate.swift
//  ImageDemo
//
//  Created by 김동현 on 
//

import UIKit
import Coordinator

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Configures and attaches the app window for the connecting scene, starts the CameraCoordinator, and makes the window key and visible.
    /// - Parameters:
    ///   - scene: The scene being connected; must be a `UIWindowScene`.
    ///   - session: The session associated with the connecting scene.
    ///   - connectionOptions: Options used to configure the scene upon connection.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // 1. scene 캡처
        guard let windowScene = scene as? UIWindowScene else { return }

        // 2. window 생성
        let window = UIWindow(windowScene: windowScene)

        // 3. root view controller 설정
        let navigationController = UINavigationController()
        let coordinator = CameraCoordinator(navigationController: navigationController)
        coordinator.start()
        
 
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}