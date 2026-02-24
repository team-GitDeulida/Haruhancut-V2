//
//  SceneDelegate.swift
//  TestUIKit
//
//  Created by 김동현 on 1/10/26.
//

import UIKit
import Coordinator
import Domain
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // 1. scene 캡처
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 2. window scene을 가져오는 windowScene을 생성자를 사용해서 UIWindow를 생성
        let window = UIWindow(windowScene: windowScene)
        
        // 3. Navigation Controller 생성
        let navigationController = UINavigationController()
        
        // 5. AppCoordinator 생성
        let appCoordinator = AppCoordinator(navigationController: navigationController)
        self.appCoordinator = appCoordinator
        self.configureForUITests()
        appCoordinator.start()

        // 4. navigationController로 window의 root view controller를 설정
        window.rootViewController = navigationController
        
        // 5. window를 설정하고 makeKeyAndVisible()
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        // 카카오 로그인
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.rx.handleOpenUrl(url: url)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

