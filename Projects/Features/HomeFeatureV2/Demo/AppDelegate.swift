//
//  AppDelegate.swift
//  HomeFeatureV2Demo
//
//  Created by 김동현 on 
//

import UIKit
import Core
import Domain
import Data
import FirebaseCore

private final class EphemeralStorage: UserDefaultsStorageProtocol {
    private var storage: [String: Any] = [:]

    func set<T>(_ value: T?, forKey key: String) {
        storage[key] = value
    }

    func get<T>(forKey key: String) -> T? {
        storage[key] as? T
    }

    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        registerDependencies()
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

extension AppDelegate {
    var container: DIContainer {
        DIContainer.shared
    }
    
    func registerDependencies() {
        let storage = EphemeralStorage()
        let userSession = UserSession(storage: storage, storageKey: "session.user")
        let groupSession = GroupSession(storage: storage, storageKey: "session.group")

        let tempUserId = "1h4ae6QmKNgyP5eQlGXsONndGun1"
        let tempGroupId = "-Opq0BagjVALrLmBjdgW"

        userSession.update(
            User(
                uid: tempUserId,
                registerDate: .now,
                loginPlatform: .apple,
                nickname: "테스트유저",
                birthdayDate: .now,
                gender: .other,
                isPushEnabled: true,
                groupId: tempGroupId
            )
        )

        groupSession.update(
            SessionGroup(
                groupId: tempGroupId,
                groupName: "테스트그룹",
                createdAt: .now,
                hostUserId: tempUserId,
                inviteCode: "TEMP1234",
                members: [tempUserId: "테스트유저"],
                postsByDate: [:]
            )
        )
        
        
        let fcmTokenStore = FCMTokenStore()
        DIContainer.shared.register(UserSession.self, dependency: userSession)
        DIContainer.shared.register(GroupSession.self, dependency: groupSession)
        DIContainer.shared.register(FCMTokenStore.self, dependency: fcmTokenStore)
        
        let kakaoLoginManager = KakaoLoginManager()
        let appleLoginManager = AppleLoginManager()
        let firebaseAuthManager = FirebaseAuthManager()
        let firebaseStorageManager = FirebaseStorageManager()
        
        // repository
        let authRepository = AuthRepositoryImpl(kakaoLoginManager: kakaoLoginManager,
                                                    appleLoginManager: appleLoginManager,
                                                    firebaseAuthManager: firebaseAuthManager,
                                                    firebaseStorageManager: firebaseStorageManager)
        let groupRepository = GroupRepositoryImpl(firebaseAuthManager: firebaseAuthManager,
                                                  firebaseStorageManager: firebaseStorageManager,
                                                  userSession: userSession)
        
        
        // usecase
        let authUseCase = AuthUsecaseImpl(authRepository: authRepository,
                                          userSession: userSession,
                                          groupSession: groupSession,
                                          fcmTokenStore: fcmTokenStore)
        DIContainer.shared.register(AuthUsecaseProtocol.self, dependency: authUseCase)
        
        let groupUseCase = GroupUsecaseImpl(groupRepository: groupRepository,
                                            userSession: userSession,
                                            groupSession: groupSession)
        DIContainer.shared.register(GroupUsecaseProtocol.self, dependency: groupUseCase)
    }
}
