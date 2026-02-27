//
//  User.swift
//  Domain
//
//  Created by 김동현 on 1/13/26.
//

import Foundation
import Core

public struct User: Codable, Equatable {
    
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

extension User: CustomStringConvertible {
//    public var description: String {
//        """
//        
//        👤 User
//        ├─ ID: \(uid)
//        ├─ registerDate: \(registerDate)
//        ├─ loginPlatform: \(loginPlatform)
//        ├─ nickname: \(nickname)
//        ├─ birthdayDate \(birthdayDate)
//        ├─ gender \(gender)
//        └─ isPushEnabled \(isPushEnabled)
//
//        """
//    }
    public var description: String {
        """
        
        👤 User
        ├─ uid:              \(uid)
        ├─ registerDate:     \(registerDate.formatted())
        ├─ loginPlatform:    \(loginPlatform.rawValue)
        ├─ nickname:         \(nickname)
        ├─ profileImageURL:  \(profileImageURL ?? "nil")
        ├─ fcmToken:         \(fcmToken.map { "\($0.prefix(6))***" } ?? "nil")
        ├─ birthdayDate:     \(birthdayDate.toDateKey())
        ├─ gender:           \(gender.rawValue)
        ├─ isPushEnabled:    \(isPushEnabled)
        └─ groupId:          \(groupId ?? "nil")
        
        """
    }
}



// MARK: - User Session
public typealias UserSession = SessionContext<User>
/*
public struct SessionUser: Codable, Equatable, CustomStringConvertible {
    public var userId: String
    public var groupId: String?
    public var nickname: String
    public var profileImageURL: String?
    public var fcmToken: String?
    public var description: String {
        """
        
        SessionUser(
        - userId:          \(userId),
        - groupId:         \(groupId ?? "nil"),
        - nickname:        \(nickname),
        - profileImageURL: \(profileImageURL ?? "nil"),
        - fcmToken:        \(fcmToken ?? "nil")
        )
        """
    }

    public init(
        userId: String,
        groupId: String?,
        nickname: String,
        profileImageURL: String?,
        fcmToken: String?
    ) {
        self.userId = userId
        self.groupId = groupId
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.fcmToken = fcmToken
    }

    public init(user: User) {
        self.userId = user.uid
        self.groupId = user.groupId
        self.nickname = user.nickname
        self.profileImageURL = user.profileImageURL
        self.fcmToken = user.fcmToken
    }
}
 */

//extension User {
//    public func toSession() -> SessionUser {
//        return SessionUser(user: self)
//    }
//}


public extension SessionContext where Model == User {
    var userId: String? { session?.uid }
    var groupId: String? { session?.groupId }
    var nickname: String? { session?.nickname }
    var profileImageURL: String? { session?.profileImageURL }
    var fcmToken: String? { session?.fcmToken }
    var hasGroup: Bool { groupId != nil }
}
