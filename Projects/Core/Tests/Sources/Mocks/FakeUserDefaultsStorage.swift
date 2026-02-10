//
//  FakeUserDefaultsStorage.swift
//  CoreTests
//
//  Created by 김동현 on 2/10/26.
//

import Foundation
@testable import Core

final class FakeUserDefaultsStorage: UserDefaultsStorageProtocol {

    private var storage: [String: Any] = [:]

    func set<T>(_ value: T?, forKey key: String) {
        storage[key] = value
    }

    func get<T>(forKey key: String) -> T? {
        storage[key] as? T
    }

    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }
}
