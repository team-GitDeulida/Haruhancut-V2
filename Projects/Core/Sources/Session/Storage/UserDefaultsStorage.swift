//
//  UserDefaultsStorage.swift
//  Core
//
//  Created by 김동현 on 1/25/26.
//

import Foundation

/*
 [사용법]
 let storage: KeyValueStorage = UserDefaultsStorage()

 // 저장
 storage.set("user_123", forKey: "userId")
 storage.set(true, forKey: "isLoggedIn")
 storage.set(Date(), forKey: "lastLoginAt")

 // 조회
 let userId: String? = storage.get(forKey: "userId")
 let isLoggedIn: Bool = storage.get(forKey: "isLoggedIn") ?? false
 let lastLogin: Date? = storage.get(forKey: "lastLoginAt")

 // 삭제
 storage.remove("userId")
 */
public protocol UserDefaultsStorageProtocol {
    func set<T>(_ value: T?, forKey: String)
    func get<T>(forKey key: String) -> T?
    func remove(_ key: String)
}

public final class UserDefaultsStorage: UserDefaultsStorageProtocol {
    
    private let defaults: UserDefaults
    
    // 테스트용 UserDefaults 주입을 위해 주입받는 구조로 구현
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    // 저장
    public func set<T>(_ value: T?, forKey: String) {
        defaults.set(value, forKey: forKey)
    }
    
    // 조회
    public func get<T>(forKey key: String) -> T? {
        return defaults.object(forKey: key) as? T
    }
    
    // 세션 초기화
    public func remove(_ key: String) {
        defaults.removeObject(forKey: key)
    }
    
}










//
//public protocol KeyValueStorage {
//    func set(_ value: Any?, forKey: String)
//    func string(forKey key: String) -> String?
//    func bool(forKey key: String) -> Bool
//    func date(forKey key: String) -> Date?
//    func data(forKey key: String) -> Data?
//    func remove(_ key: String)
//}
//
//public final class UserDefaultsStorage: KeyValueStorage {
//    private let defaults: UserDefaults
//    
//    // 테스트용 UserDefaults 주입을 위해 주입받는 구조로 구현
//    public init(defaults: UserDefaults = .standard) {
//        self.defaults = defaults
//    }
//    
//    // Any 저장
//    public func set(_ value: Any?, forKey: String) {
//        defaults.set(value, forKey: forKey)
//    }
//    
//    // string 조회
//    public func string(forKey: String) -> String? {
//        defaults.string(forKey: forKey)
//    }
//    
//    // bool 조회
//    public func bool(forKey key: String) -> Bool {
//        defaults.bool(forKey: key)
//    }
//    
//    // date 조회
//    public func date(forKey key: String) -> Date? {
//        defaults.object(forKey: key) as? Date
//    }
//    
//    // data 조회
//    public func data(forKey key: String) -> Data? {
//        defaults.data(forKey: key)
//    }
//    
//    // 세션 초기화
//    public func remove(_ key: String) {
//        defaults.removeObject(forKey: key)
//    }
//    
//}


