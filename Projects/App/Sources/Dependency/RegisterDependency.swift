//
//  RegisterDependency.swift
//  App
//
//  Created by 김동현 on 1/12/26.
//

import Core

extension AppDelegate {
    var container: DIContainer {
        DIContainer.shared
    }
    
    func registerDependencies() {
        let authRepository = AuthRepository()
    }
}
