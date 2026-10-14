//
//  MemoryStorage.swift
//  DomainTests
//
//  Created by 김동현 on 10/12/26.
//

import Core

/// Session을 메모리에만 저장하는 테스트용 저장소입니다.
final class MemoryStorage: StorageProtocol {
    private var values: [String: Any] = [:]

    func write<T: Encodable>(_ value: T, to key: String) {
        values[key] = value
    }

    func read<T: Decodable>(_ key: String) -> T? {
        values[key] as? T
    }

    func remove(_ key: String) {
        values[key] = nil
    }
}
