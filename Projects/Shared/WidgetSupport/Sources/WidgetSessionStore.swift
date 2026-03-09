//
//  WidgetSessionStore.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Foundation
import Domain

public enum WidgetSessionStore {
    
    private static func sessionFile() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetPaths.appGroupId)?
            .appendingPathComponent("Session", isDirectory: true)
            .appendingPathComponent("user.json")
    }
    
    public static func saveUser(_ user: User) {

        guard let url = sessionFile() else { return }

        let folder = url.deletingLastPathComponent()

        try? FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        guard let data = try? JSONEncoder().encode(user) else { return }

        try? data.write(to: url)

        print("📦 WidgetSession saved:", user.groupId ?? "nil")
    }
    
    public static func loadUser() -> User? {
        guard let url = sessionFile(),
              let data = try? Data(contentsOf: url
              ) else {
            return nil
        }
        return try? JSONDecoder().decode(User.self, from: data)
    }
}
