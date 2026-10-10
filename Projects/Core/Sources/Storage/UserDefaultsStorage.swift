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

 try storage.write(user, to: "session.user")
 let user: User? = storage.read("session.user")
 storage.remove("session.user")
 */

/// UserDefaults에 저장하는 저장소입니다. 키는 UserDefaults 키입니다.
public final class UserDefaultsStorage {

    private let defaults: UserDefaults

    // 테스트용 UserDefaults 주입을 위해 주입받는 구조로 구현
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

// MARK: - StorageProtocol
extension UserDefaultsStorage: StorageProtocol {
    public func write<T: Encodable>(_ value: T, to key: String) throws {
        defaults.set(try encode(value), forKey: key)
    }

    public func read<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return decode(data)
    }

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


