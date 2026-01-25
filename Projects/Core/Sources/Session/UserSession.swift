//
//  UserSession.swift
//  App
//
//  Created by 김동현 on 1/25/26.
//

import Foundation

// Auth Context
public struct SessionUser: Codable, Equatable {
    public let userId: String
    
    public init(userId: String) {
        self.userId = userId
    }
}

public protocol UserSessionType {
    typealias SessionChangeHandler = (SessionUser?) -> Void
    
    var sessionUser: SessionUser? { get }
    var isLoggedIn: Bool { get }
    
    func bind(_ handler: @escaping SessionChangeHandler)
    func update(_ user: SessionUser)
    func clear()
}

public final class UserSession: UserSessionType {

    private let storage: KeyValueStorage
    private var onSessionChanged: (SessionChangeHandler)?
    
    private enum Key {
        static let user = "session.user"
    }
    
    public init(storage: KeyValueStorage) {
        self.storage = storage
    }
    
    public var sessionUser: SessionUser? {
        get {
            guard let data = storage.data(forKey: Key.user) else { return nil }
            return try? JSONDecoder().decode(SessionUser.self, from: data)
        }
        
        set {
            let data = try? JSONEncoder().encode(newValue)
            storage.set(data, forKey: Key.user)
        }
    }
    
    public func bind(_ handler: @escaping SessionChangeHandler) {
        self.onSessionChanged = handler
        handler(sessionUser)
    }
    
    public func update(_ user: SessionUser) {
        self.onSessionChanged?(user) // 상태가 바뀌면 값을 만들어서 호출 -> 받는쪽:  bind로 등록한 외부 객체
        self.sessionUser = user
    }
    
    public func clear() {
        storage.remove(Key.user)
        onSessionChanged?(nil)
    }
    
    public var isLoggedIn: Bool {
        self.sessionUser != nil
    }
}
