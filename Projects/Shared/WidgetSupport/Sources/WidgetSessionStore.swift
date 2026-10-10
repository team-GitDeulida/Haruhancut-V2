//
//  WidgetSessionStore.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Core
import Domain
import Foundation

/// 위젯이 그룹을 찾을 때 쓰는 사용자 정보를 App Group 저장소에 저장합니다.
public struct WidgetSessionStore {

    private let storage: StorageProtocol?

    /// - Parameter storage: 사용자 정보를 저장할 저장소. 기본값은 위젯과 공유하는 App Group 저장소입니다.
    public init(storage: StorageProtocol? = WidgetPaths.appGroupStorage()) {
        self.storage = storage
    }
}

// MARK: - 사용자 저장·조회
public extension WidgetSessionStore {
    func saveUser(_ user: User) {
        guard let storage else { return }

        try? storage.write(user, to: WidgetPaths.sessionFile)

        print("[📦] [WidgetSession saved]", user.groupId ?? "nil")
    }

    func loadUser() -> User? {
        storage?.read(WidgetPaths.sessionFile)
    }
}
