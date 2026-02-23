//
//  RegisterDependency.swift
//  App
//
//  Created by 김동현 on 1/12/26.
//

import Core
import Data
import Domain
import FirebaseDatabase

extension AppDelegate {
    var container: DIContainer {
        DIContainer.shared
    }
    
    func registerDependencies() {
        
        // session
        let storage = UserDefaultsStorage()
        let userSession = UserSession(storage: storage, storageKey: "session.user")
        let groupSession = GroupSession(storage: storage, storageKey: "session.group")
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
                                          fcmTokenStore: fcmTokenStore)
        DIContainer.shared.register(AuthUsecaseProtocol.self, dependency: authUseCase)
        
        let groupUseCase = GroupUsecaseImpl(groupRepository: groupRepository,
                                            userSession: userSession,
                                            groupSession: groupSession)
        DIContainer.shared.register(GroupUsecaseProtocol.self, dependency: groupUseCase)
    }
}
