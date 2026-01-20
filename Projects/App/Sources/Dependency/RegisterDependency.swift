//
//  RegisterDependency.swift
//  App
//
//  Created by 김동현 on 1/12/26.
//

import Core
import Data
import Domain

extension AppDelegate {
    var container: DIContainer {
        DIContainer.shared
    }
    
    func registerDependencies() {
        let kakaoLoginManager = KakaoLoginManager()
        let appleLoginManager = AppleLoginManager()
        let firebaseAuthManager = FirebaseAuthManager()
        let firebaseStorageManager = FirebaseStorageManager()
        let signInRepository = SignInRepositoryImpl(kakaoLoginManager: kakaoLoginManager, appleLoginManager: appleLoginManager, firebaseAuthManager: firebaseAuthManager as! FirebaseAuthManagerProtocol, firebaseStorageManager: firebaseStorageManager)
        let signInUseCase = SignInUsecaseImpl(signInRepository: signInRepository)
        DIContainer.shared.register(SignInUsecaseProtocol.self, dependency: signInUseCase)
    }
}
