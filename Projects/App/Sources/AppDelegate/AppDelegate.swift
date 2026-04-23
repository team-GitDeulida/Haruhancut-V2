//
//  AppDelegate.swift
//  TestUIKit
//
//  Created by 김동현 on 1/10/26.
//

import UIKit
import OSLog

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
    private static let logger = Logger(
        subsystem: "com.indextrown.Haruhancut",
        category: "AppDelegate"
    )
    
    override init() {
        super.init()
        
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            print("현재 빌드번호:", buildNumber)
            Self.logger.notice("AppDelegate.init build=\(buildNumber, privacy: .public)")
        } else {
            Self.logger.error("AppDelegate.init missing build number")
        }
        Self.logger.notice("AppDelegate.init completed")
        
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
        Self.logger.notice("didFinishLaunching start")
        
        // AppLifeCycle
        registerDependencies()
        Self.logger.notice("dependencies registered")
        
        // Firebase
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        FirebaseApp.configure()
        Self.logger.notice("Firebase configured")
        
        // fcm(MessagingDelegate), fcm -> session save
        Messaging.messaging().delegate = self
        Self.logger.notice("Messaging delegate set")
        
        // 알림 권한 호출
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                Self.logger.error("notification auth error: \(error.localizedDescription, privacy: .public)")
            } else {
                Self.logger.notice("notification auth granted=\(granted, privacy: .public)")
            }
            guard granted else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                Self.logger.notice("registerForRemoteNotifications called")
            }
        }
        
        // Kakao
        if let nativeAppKey: String = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
            RxKakaoSDK.initSDK(appKey: nativeAppKey, loggingEnable: false)
            Self.logger.notice("Kakao SDK initialized")
        } else {
            Self.logger.error("KAKAO_NATIVE_APP_KEY missing from Info.plist")
        }
        
        Self.logger.notice("didFinishLaunching end")
        
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
