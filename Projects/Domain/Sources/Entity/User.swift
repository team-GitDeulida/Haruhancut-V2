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
    
    public init(uid: String, registerDate: Date, nickname: String, profileImageURL: String? = nil, fcmToken: String? = nil, birthdayDate: Date, gender: Gender, isPushEnabled: Bool, groupId: String? = nil) {
        self.uid = uid
        self.registerDate = registerDate
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.fcmToken = fcmToken
        self.birthdayDate = birthdayDate
        self.gender = gender
        self.isPushEnabled = isPushEnabled
        self.groupId = groupId
    }
}
