//
//  SceneDelegate.swift
//  AuthDemo
//
//  Created by 김동현 on 
//

import UIKit
import AuthFeatureInterface
import AuthFeature

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

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
        let builder = AuthFeatureBuilder()
        let signIn = builder.makeSignIn()
        window.rootViewController = signIn.vc
        
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
