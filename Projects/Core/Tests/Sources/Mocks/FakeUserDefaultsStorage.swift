//
//  FakeUserDefaultsStorage.swift
//  CoreTests
//
//  Created by 김동현 on 2/10/26.
//

import Foundation
@testable import Core

final class FakeUserDefaultsStorage: StorageProtocol {

    private var storage: [String: Any] = [:]

    func write<T: Encodable>(_ value: T, to key: String) {
        storage[key] = value
    }

    func read<T: Decodable>(_ key: String) -> T? {
        storage[key] as? T
    }

    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }
}
