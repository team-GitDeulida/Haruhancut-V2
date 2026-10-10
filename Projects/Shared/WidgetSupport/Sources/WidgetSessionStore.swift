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

    private let storage: FileStorageProtocol?

    /// - Parameter storage: 사용자 정보를 저장할 저장소. 기본값은 위젯과 공유하는 App Group 저장소입니다.
    public init(storage: FileStorageProtocol? = WidgetPaths.appGroupStorage()) {
        self.storage = storage
    }

    public func saveUser(_ user: User) {
        guard
            let storage,
            let data = try? JSONEncoder().encode(user)
        else { return }

        try? storage.write(data, to: WidgetPaths.sessionFile)

        print("[📦] [WidgetSession saved]", user.groupId ?? "nil")
    }

    public func loadUser() -> User? {
        guard let data = storage?.read(WidgetPaths.sessionFile) else {
            return nil
        }
        return try? JSONDecoder().decode(User.self, from: data)
    }
}
