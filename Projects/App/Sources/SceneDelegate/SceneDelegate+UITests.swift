//
//  SceneDelegate+UITests.swift
//  App
//
//  Created by 김동현 on 2/24/26.
//

import UIKit
import Core
import Domain

extension SceneDelegate {
    func configureForUITests() {
        let enviroment = ProcessInfo.processInfo.environment
        guard let uid = enviroment["TEST_USER_UID"] else { return }
        
        let authUsecase = DIContainer.shared.resolve(AuthUsecaseProtocol.self)
        let userSession = DIContainer.shared.resolve(UserSession.self)
        let groupSession = DIContainer.shared.resolve(GroupSession.self)
        
        // 1. 테스트 시작 시 세션 초기화
        userSession.clear()
        groupSession.clear()
        Logger.d("테스트 시작: 기존 세션 초기화")
        
        // 2. 테스트 유저 주입
        authUsecase.bootstrapUserSession(uid: uid)
            .subscribe()
            .disposed(by: disposeBag)
    }
}


