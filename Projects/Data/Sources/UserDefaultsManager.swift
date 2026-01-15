//
//  UserDefaultsManager.swift
//  Core
//
//  Created by 김동현 on 1/15/26.
//

import Foundation
import Domain

public final class UserDefaultsManager {
    public static let shared = UserDefaultsManager()
    private init() {}
    
    private let userKey = "cachedUser"
    private let signupKey = "isSignupCompleted"
    private let groupKey = "cachedGroup"
    private let notificationKey = "notificationsEnabled"
    
    // MARK: - 유저
    /// 저장 - create
    public func saveUser(_ user: User) {
        let dto = user.toDTO()
        guard let data = try? JSONEncoder().encode(dto) else { return }
        UserDefaults.standard.set(data, forKey: userKey)
    }

    /// 불러오기 - read
    public func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        guard let dto = try? JSONDecoder().decode(UserDTO.self, from: data) else { return nil }
        return dto.toModel()
    }
    
    // 삭제 - delete
    public func removeUser() {
        UserDefaults.standard.removeObject(forKey: userKey)
        // print("캐시 유저 삭제: \(String(describing: self.loadUser()))")
    }
    
    // MARK: - 그룹
    /// 저장 - create
//    public func saveGroup(_ group: HCGroup) {
//        let dto = group.toDTO()
//        guard let data = try? JSONEncoder().encode(dto) else { return }
//        UserDefaults.standard.set(data, forKey: groupKey)
//    }
//    
//    /// 불러오기 - read
//    public func loadGroup() -> HCGroup? {
//        guard let data = UserDefaults.standard.data(forKey: groupKey) else { return nil }
//        guard let dto = try? JSONDecoder().decode(HCGroupDTO.self, from: data) else { return nil }
//        return dto.toModel()
//    }
//    
//    // 삭제 - delete
//    public func removeGroup() {
//        UserDefaults.standard.removeObject(forKey: groupKey)
//        // print("캐시 그룹 삭제: \(String(describing: self.loadGroup()))")
//    }
    
    // MARK: - 알람
    /// 저장 - create
    public func setNotificationEnabled(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: notificationKey)
    }
    
    /// 불러오기 - read
    public func loadNotificationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: notificationKey)
    }
}
