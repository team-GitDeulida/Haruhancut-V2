//
//  RegisterDependency.swift
//  App
//
//  Created by 김동현 on 1/12/26.
//

import Core
import Data
import Domain

extension SceneDelegate {
    var container: DIContainer {
        DIContainer.shared
    }
    
    func registerDependencies() {
        
        // session
        let storage = UserDefaultsStorage()
        let userSession = UserSession(storage: storage)
        DIContainer.shared.register(UserSessionType.self, dependency: userSession)
        
        let kakaoLoginManager = KakaoLoginManager()
        let appleLoginManager = AppleLoginManager()
        let firebaseAuthManager = FirebaseAuthManager()
        let firebaseStorageManager = FirebaseStorageManager()
        
        // repository
        let signInRepository = SignInRepositoryImpl(kakaoLoginManager: kakaoLoginManager,
                                                    appleLoginManager: appleLoginManager,
                                                    firebaseAuthManager: firebaseAuthManager,
                                                    firebaseStorageManager: firebaseStorageManager, userSession: userSession)
        let groupRepository = GroupRepositoryImpl(firebaseAuthManager: firebaseAuthManager, firebaseStorageManager: firebaseStorageManager)
        
        
        // usecase
        let signInUseCase = SignInUsecaseImpl(signInRepository: signInRepository)
        DIContainer.shared.register(SignInUsecaseProtocol.self, dependency: signInUseCase)
        
        let groupUseCase = GroupUsecaseImpl(groupRepository: groupRepository)
        DIContainer.shared.register(GroupUsecaseProtocol.self, dependency: groupUseCase)
    }
}
