//
//  StorageProtocol.swift
//  Core
//
//  Created by 김동현 on 10/10/26.
//

import Foundation

/*
 [사용법]
 let storage: StorageProtocol = UserDefaultsStorage() // 또는 FileStorage

 // 모델 (JSON으로 저장)
 try storage.write(user, to: "session.user")
 let user: User? = storage.read("session.user")

 // 데이터 (그대로 저장)
 try storage.write(imageData, to: "Photos/photo.jpg")
 let imageData: Data? = storage.read("Photos/photo.jpg")

 storage.remove("session.user")
 */

/// 키로 값을 저장·조회·삭제(CRUD)하는 저장소 계약입니다.
///
/// `Data`는 그대로 저장하고, 그 밖의 값은 JSON으로 바꿔 저장합니다.
/// 구현체는 `UserDefaultsStorage`(UserDefaults 키)와 `FileStorage`(기준 폴더에서 시작하는
/// 상대 경로)입니다.
public protocol StorageProtocol {
    /// 값을 저장합니다. 같은 키에 값이 있으면 덮어씁니다.
    func write<T: Encodable>(_ value: T, to key: String) throws

    /// 저장된 값을 읽습니다. 값이 없거나 타입이 맞지 않으면 `nil`입니다.
    func read<T: Decodable>(_ key: String) -> T?

    /// 저장된 값을 지웁니다. 없으면 아무 일도 하지 않습니다.
    func remove(_ key: String)
}

// MARK: - Core 구현체가 쓰는 변환
/// 값과 저장 형식(`Data`) 사이를 바꿉니다. `Data`는 그대로, 그 밖의 값은 JSON입니다.
extension StorageProtocol {
    /// 값을 저장 형식으로 바꿉니다. `Data`는 그대로, 그 밖의 값은 JSON으로 인코딩합니다.
    func encode<T: Encodable>(_ value: T) throws -> Data {
        if let data = value as? Data {
            return data
        }
        return try JSONEncoder().encode(value)
    }

    /// 저장 형식을 값으로 바꿉니다. `Data`를 원하면 그대로, 그 밖의 타입은 JSON으로 디코딩하고 실패하면 `nil`입니다.
    func decode<T: Decodable>(_ data: Data) -> T? {
        if let data = data as? T {
            return data
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
