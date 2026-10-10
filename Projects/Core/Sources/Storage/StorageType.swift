//
//  StorageType.swift
//  Core
//
//  Created by 김동현 on 10/10/26.
//

import Foundation

/// 키로 데이터를 저장·조회·삭제(CRUD)하는 저장소의 공통 계약입니다.
///
/// 저장 방식별 CRUD는 이 계약을 채택한 프로토콜의 익스텐션에 미리 구현돼 있습니다.
/// - `UserDefaultsStorageType`: `defaults`만 제공하면 UserDefaults에 저장합니다.
/// - `FileStorageType`: `baseURL`·`fileManager`만 제공하면 기준 폴더 아래 파일에 저장합니다.
///
/// 저장소에만 필요한 기능은 구현체의 익스텐션에 추가합니다. (예: `FileStorage.contentsOfDirectory`)
/// 저장소를 쓰는 쪽은 CRUD만 필요하면 `StorageType`에 의존합니다.
public protocol StorageType {
    /// 데이터를 저장합니다. 같은 키에 값이 있으면 덮어씁니다.
    func write(_ data: Data, to key: String) throws

    /// 저장된 데이터를 읽습니다. 없으면 `nil`입니다.
    func read(_ key: String) -> Data?

    /// 저장된 값을 지웁니다. 없으면 아무 일도 하지 않습니다.
    func remove(_ key: String)
}
