//
//  UserDefaultsStorage.swift
//  Core
//
//  Created by 김동현 on 1/25/26.
//

import Foundation

/*
 [사용법]
 let storage = UserDefaultsStorage()

 // 공통 CRUD (StorageType)
 storage.write(data, to: "session.user")
 let data = storage.read("session.user")
 storage.remove("session.user")

 // UserDefaults가 담을 수 있는 값을 그대로 저장·조회 (UserDefaultsStorage 익스텐션)
 storage.set("user_123", forKey: "userId")
 storage.set(true, forKey: "isLoggedIn")
 let userId: String? = storage.get(forKey: "userId")
 let isLoggedIn: Bool = storage.get(forKey: "isLoggedIn") ?? false
 */

/// UserDefaults에 저장하는 저장소입니다.
///
/// `defaults`만 제공하면 공통 CRUD(`StorageType`)는 아래 익스텐션의 기본 구현을 씁니다.
public protocol UserDefaultsStorageType: StorageType {
    var defaults: UserDefaults { get }
}

public extension UserDefaultsStorageType {
    func write(_ data: Data, to key: String) {
        defaults.set(data, forKey: key)
    }

    func read(_ key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func remove(_ key: String) {
        defaults.removeObject(forKey: key)
    }
}

/// `UserDefaults.standard` 또는 주입한 UserDefaults를 쓰는 저장소입니다.
public final class UserDefaultsStorage: UserDefaultsStorageType {

    public let defaults: UserDefaults

    // 테스트용 UserDefaults 주입을 위해 주입받는 구조로 구현
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

/// UserDefaults가 담을 수 있는 값(문자열, 숫자, 날짜, 데이터 등)을 그대로 저장·조회합니다.
public extension UserDefaultsStorage {
    // 저장
    func set<T>(_ value: T?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    // 조회
    func get<T>(forKey key: String) -> T? {
        defaults.object(forKey: key) as? T
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


