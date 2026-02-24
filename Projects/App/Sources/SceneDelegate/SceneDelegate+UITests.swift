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
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-UITest") else { return }
        let userSession = DIContainer.shared.resolve(UserSession.self)
        
        var uid: String?
        var hasGroup = false
        
        if let index = arguments.firstIndex(of: "-MockUID"),
           arguments.count > index + 1 {
            uid = arguments[index + 1]
        }
        
        if arguments.contains("-HasGroup") {
            hasGroup = true
        }
        
        if let uid {
            userSession.mockLogin(uid: uid, hasGroup: hasGroup)
        }
    }
}
