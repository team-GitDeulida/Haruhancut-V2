//
//  AppDelegate.swift
//  AuthDemo
//
//  Created by 김동현 on 
//

import UIKit
import Core
import AuthFeatureInterface
import Domain
//import Data


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let container = DIContainer.shared
        
        container.register(SignInRepositoryProtocol.self,
                           dependency: StubSignInRepositoryImpl())
        
        container.register(SignInUsecaseProtocol.self,
                                    dependency: StubSignInUsecaseImpl())
        
        return true
    }

    // MARK: - UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Called when the user discards a scene session.
    }
}
