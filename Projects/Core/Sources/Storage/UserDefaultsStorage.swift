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
