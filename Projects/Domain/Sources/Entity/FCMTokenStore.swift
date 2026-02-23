//
//  FCMTokenStore.swift
//  Domain
//
//  Created by 김동현 on 2/23/26.
//

import Foundation

public final class FCMTokenStore {
    public var latestToken: String?
    
    public init() {}
}

// 필요시 사용 예정
//final class FCMTokenStore {
//
//    private let key = "fcm.latest.token"
//
//    var latestToken: String? {
//        get {
//            UserDefaults.standard.string(forKey: key)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: key)
//        }
//    }
//}
