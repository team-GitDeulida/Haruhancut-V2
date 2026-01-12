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
        let authRepository = AuthRepositoryImpl()
        let authUseCase = AuthUsecaseImpl(authRepository: authRepository)
        DIContainer.shared.register(AuthUsecaseProtocol.self, dependency: authUseCase)
    }
}
