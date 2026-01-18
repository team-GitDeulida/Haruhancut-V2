//
//  UserBuilder.swift
//  AuthFeature
//
//  Created by 김동현 on 1/17/26.
//

import UIKit
import Domain

final class UserBuilder {
    
    private let loginPlatform: User.LoginPlatform
    private var nickname: String?
    private var birthday: Date?
    private var profileImage: UIImage?
    
    init(loginPlatform: User.LoginPlatform) {
        self.loginPlatform = loginPlatform
    }
    
    func withNickname(_ nickname: String) {
        self.nickname = nickname
    }
    
    func withBirthday(_ birthday: Date) {
        self.birthday = birthday
    }
    
    func withProfileImage(_ image: UIImage?) {
        self.profileImage = image
    }
    
    @discardableResult
    func build() -> User {
        let user = User(uid: "",
                        registerDate: .now,
                        loginPlatform: loginPlatform,
                        nickname: nickname ?? "", birthdayDate: birthday ?? .now, gender: .other, isPushEnabled: true)
        print("테스트: \(user)")
        return user
    }
}

