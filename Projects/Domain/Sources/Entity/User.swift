//
//  User.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import Foundation


public struct User: Encodable {
    
    public var uid: String
    public let registerDate: Date
    public let loginPlatform: LoginPlatform
    public var nickname: String
    public var profileImageURL: String?
    public var fcmToken: String?
    public var birthdayDate: Date
    public var gender: Gender
    public var isPushEnabled: Bool
    public var groupId: String?
    
    // 성별
    public enum Gender: String, Codable {
        case male = "남자"
        case female = "여자"
        case other = "비공개"
    }

    // 로그인 플랫폼
    public enum LoginPlatform: String, Codable {
        case kakao = "kakao"
        case apple = "apple"
    }
    
    public init(uid: String, registerDate: Date, loginPlatform: LoginPlatform, nickname: String, profileImageURL: String? = nil, fcmToken: String? = nil, birthdayDate: Date, gender: Gender, isPushEnabled: Bool, groupId: String? = nil) {
        self.uid = uid
        self.registerDate = registerDate
        self.loginPlatform = loginPlatform
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.fcmToken = fcmToken
        self.birthdayDate = birthdayDate
        self.gender = gender
        self.isPushEnabled = isPushEnabled
        self.groupId = groupId
    }
}

extension User {
    public static var sampleUser1: User {
        User(uid: "stub-uid",
             registerDate: Date(),
             loginPlatform: .apple,
             nickname: "stub-nickname-apple",
             birthdayDate: .now,
             gender: .male,
             isPushEnabled: true
        )
    }
}
