//
//  AppDelegate.swift
//  TestUIKit
//
//  Created by 김동현 on 1/10/26.
//

import UIKit

// 파이어베이스
import FirebaseCore
import FirebaseMessaging

// kakao
import KakaoSDKAuth
import RxKakaoSDKCommon

import Domain
import Core


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    override init() {
        super.init()
        
        
        /*
        print("🔥 Firebase configured in AppDelegate.init")
        
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ GoogleService-Info.plist path:", path)
            if let dict = NSDictionary(contentsOfFile: path) {
                print("✅ CLIENT_ID:", dict["CLIENT_ID"] ?? "nil")
                print("✅ REVERSED_CLIENT_ID:", dict["REVERSED_CLIENT_ID"] ?? "nil")
            }
        } else {
            print("❌ GoogleService-Info.plist NOT FOUND in bundle")
        }
         */

    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // AppLifeCycle
        registerDependencies()
        
        
        // Firebase
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        FirebaseApp.configure()
        
        // fcm(MessagingDelegate), fcm -> session save
        Messaging.messaging().delegate = self
        
        // Kakao
        if let nativeAppKey: String = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
            RxKakaoSDK.initSDK(appKey: nativeAppKey, loggingEnable: false)
        }
        
        return true
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 카카오톡 로그인
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.rx.handleOpenUrl(url: url)
        }
        
        return false
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// -MigrateManager.swift -AuthApiCommon.swift -Api.swift
