//
//  FakeUserDefaultsStorage.swift
//  CoreTests
//
//  Created by 김동현 on 2/10/26.
//

import Foundation
@testable import Core

final class FakeUserDefaultsStorage: StorageType {

    private var storage: [String: Data] = [:]

    func write(_ data: Data, to key: String) {
        storage[key] = data
    }

    func read(_ key: String) -> Data? {
        storage[key]
    }

    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }
}
