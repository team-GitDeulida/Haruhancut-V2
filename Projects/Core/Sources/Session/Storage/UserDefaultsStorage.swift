//
//  UserDefaultsStorage.swift
//  Core
//
//  Created by 김동현 on 1/25/26.
//

import Foundation

public protocol KeyValueStorage {
    func set(_ value: Any?, forKey: String)
    func string(forKey key: String) -> String?
    func bool(forKey key: String) -> Bool
    func date(forKey key: String) -> Date?
    func data(forKey key: String) -> Data?
    func remove(_ key: String)
}

public final class UserDefaultsStorage: KeyValueStorage {
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    // 저장
    public func set(_ value: Any?, forKey: String) {
        defaults.set(value, forKey: forKey)
    }
    
    // string 조회
    public func string(forKey: String) -> String? {
        defaults.string(forKey: forKey)
    }
    
    // bool 조회
    public func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }
    
    // date 조회
    public func date(forKey key: String) -> Date? {
        defaults.object(forKey: key) as? Date
    }
    
    // data 조회
    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }
    
    // 세션 초기화
    public func remove(_ key: String) {
        defaults.removeObject(forKey: key)
    }
    
}
