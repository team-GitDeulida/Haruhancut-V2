//
//  UserDto.swift
//  Data
//
//  Created by 김동현 on 1/15/26.
//

import Foundation
import Domain

// MARK: - DTO
public struct UserDTO: Codable { /// Json -> Swift 객체(서버 응답용)
    public let uid: String?
    public let registerDate: String?
    public let loginPlatform: String?
    public let nickname: String?
    public let profileImageURL: String?
    public let fcmToken: String?
    public let birthdayDate: String?
    public let gender: String?
    public let isPushEnabled: Bool?
    public let groupId: String?
    
    public init(uid: String?, registerDate: String?, loginPlatform: String?, nickname: String?, profileImageURL: String?, fcmToken: String?, birthdayDate: String?, gender: String?, isPushEnabled: Bool?, groupId: String?) {
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

extension UserDTO {
    public func toModel() -> User? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let uid = uid,
            let registerDateStr = registerDate,
            let registerDate = formatter.date(from: registerDateStr),
            let loginPlatformStr = loginPlatform,
            let loginPlatform = User.LoginPlatform(rawValue: loginPlatformStr),
            let nickname = nickname,
            let birthdayDateStr = birthdayDate,
            let birthdayDate = formatter.date(from: birthdayDateStr),
            let genderStr = gender,
            let gender = User.Gender(rawValue: genderStr),
            let isPushEnabled = isPushEnabled
        else {
            return nil
        }
        
        return User(
            uid: uid,
            registerDate: registerDate,
            loginPlatform: loginPlatform,
            nickname: nickname,
            profileImageURL: profileImageURL,
            fcmToken: fcmToken,
            birthdayDate: birthdayDate,
            gender: gender,
            isPushEnabled: isPushEnabled,
            groupId: groupId
        )
    }
}

// MARK: - toDTO
extension User {
    public func toDTO() -> UserDTO {
        
        let formatter = ISO8601DateFormatter()
        return UserDTO(
            uid: uid,
            registerDate: formatter.string(from: registerDate),
            loginPlatform: loginPlatform.rawValue,
            nickname: nickname,
            profileImageURL: profileImageURL,
            fcmToken: fcmToken,
            birthdayDate: formatter.string(from: birthdayDate),
            gender: gender.rawValue,
            isPushEnabled: isPushEnabled,
            groupId: groupId)
    }
}

