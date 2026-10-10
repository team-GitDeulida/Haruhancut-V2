//
//  StorageType.swift
//  Core
//
//  Created by 김동현 on 10/10/26.
//

import Foundation

/// 키로 데이터를 저장·조회·삭제(CRUD)하는 저장소의 공통 계약입니다.
///
/// 키의 뜻은 저장소마다 다릅니다. `UserDefaultsStorage`는 UserDefaults 키,
/// `FileStorage`는 기준 폴더에서 시작하는 상대 경로(예: `Session/user.json`)입니다.
/// 저장소마다 필요한 기능은 이 계약을 채택한 프로토콜(`UserDefaultsStorageProtocol`,
/// `FileStorageProtocol`)에 추가합니다.
public protocol StorageType {
    /// 데이터를 저장합니다. 같은 키에 값이 있으면 덮어씁니다.
    func write(_ data: Data, to key: String) throws

    /// 저장된 데이터를 읽습니다. 없으면 `nil`입니다.
    func read(_ key: String) -> Data?

    /// 저장된 값을 지웁니다. 없으면 아무 일도 하지 않습니다.
    func remove(_ key: String)
}
