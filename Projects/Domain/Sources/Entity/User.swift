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
    
    static var mockUser: User {
        User(uid: "ea0PjmlvbvYjD2IRAU0vyrq6hz42",
             registerDate: .now,
             loginPlatform: .apple,
             nickname: "애플동",
             profileImageURL: "https://firebasestorage.googleapis.com:443/v0/b/haruhancut-kor.firebasestorage.app/o/users%2Fea0PjmlvbvYjD2IRAU0vyrq6hz42%2Fprofile.jpg?alt=media&token=2944dd6f-c427-4dd5-a635-601a2fbf0c51",
             fcmToken: "eG_Jsw***",
             birthdayDate: .now,
             gender: .other,
             isPushEnabled: true,
             groupId: "-OT12dNjZiv2ZddIVFLT"
        )
    }
    
    static var mockUser2: User {
        User(uid: "T9RQRMJQOeUl8pb52y1SEfpS7nj1",
             registerDate: .now,
             loginPlatform: .kakao,
             nickname: "Index",
             profileImageURL: nil,
             birthdayDate: .now,
             gender: .other,
             isPushEnabled: true,
             groupId: "-Okw4Mg5pfc9QfqySuEA"
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

// == User Session
public extension SessionContext where Model == User {
    var userId: String? { session?.uid }
    var groupId: String? { session?.groupId }
    var nickname: String? { session?.nickname }
    var profileImageURL: String? { session?.profileImageURL }
    var fcmToken: String? { session?.fcmToken }
    var hasGroup: Bool { groupId != nil }
}

