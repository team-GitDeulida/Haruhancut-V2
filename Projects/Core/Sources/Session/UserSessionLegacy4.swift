//
//  GroupSession.swift
//  Core
//
//  Created by 김동현 on 1/25/26.
//

/*
import Foundation

// User, Group, etc...
public protocol SessionModel: Codable, Equatable, CustomStringConvertible { }
public typealias UserSession = SessionContext<SessionUser>



public struct SessionGroup: SessionModel {
    public let groupId: String
    public let groupName: String
    public let createdAt: Date
    public let hostUserId: String
    public let inviteCode: String
    public var members: [String: String]
    public var description: String {
        ""
    }
}

public struct SessionUser: SessionModel {
    public var userId: String
    public var groupId: String?
    public var nickname: String
    public var profileImageURL: String?
    
    public init(
        userId: String,
        groupId: String?,
        nickname: String,
        profileImageURL: String?
    ) {
        self.userId = userId
        self.groupId = groupId
        self.nickname = nickname
        self.profileImageURL = profileImageURL
    }
    
    public var description: String {
        """
        
        SessionUser(
        - userId:          \(userId),
        - groupId:         \(groupId ?? "nil"),
        - nickname:        \(nickname),
        - profileImageURL: \(profileImageURL ?? "nil")
        )
        """
    }
}

public protocol SessionType {
    associatedtype Model: SessionModel
    typealias SessionChangeHandler = (Model?) -> Void
    
    var session: Model? { get }
    var hasSession: Bool { get }
    
    func bind(_ handler: @escaping SessionChangeHandler)
    func observe(_ handler: @escaping SessionChangeHandler)
    func update(_ model: Model)
    func update<Value>(
        _ keyPath: WritableKeyPath<Model, Value>,
        _ value: Value
    )
    func clear()
}

public final class SessionContext<Model: SessionModel>: SessionType {
    public typealias SessionChangeHandler = (Model?) -> Void
    private let storage: UserDefaultsStorageProtocol
    private let storageKey: String
    private var cached: Model?
    private var onSessionChanged: SessionChangeHandler?
    
    public init(
        storage: UserDefaultsStorageProtocol = UserDefaultsStorage(),
        storageKey: String
    ) {
        self.storage = storage
        self.storageKey = storageKey
        self.cached = loadFromStorage()
        Logger.d(cached?.description ?? "nil")
    }
}

// MARK: - Private
private extension SessionContext {
    func loadFromStorage() -> Model? {
        guard let data: Data = storage.get(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Model.self, from: data)
    }
    
    func saveToStorage(_ model: Model) {
        let data = try? JSONEncoder().encode(model)
        storage.set(data, forKey: storageKey)
    }
}

// MARK: - Public API
public extension SessionContext {

    var session: Model? { cached }
    var hasSession: Bool { cached != nil }

    func bind(_ handler: @escaping SessionChangeHandler) {
        onSessionChanged = handler
        handler(session)
    }

    func observe(_ handler: @escaping SessionChangeHandler) {
        onSessionChanged = handler
    }

    func update(_ model: Model) {
        cached = model
        saveToStorage(model)
        onSessionChanged?(model)
    }

    func clear() {
        cached = nil
        storage.remove(storageKey)
        onSessionChanged?(nil)
    }
}

// MARK: - KeyPath Update
public extension SessionContext {
    func update<Value>(
        _ keyPath: WritableKeyPath<Model, Value>,
        _ value: Value
    ) {
        guard var current = cached else { return }

        current[keyPath: keyPath] = value
        cached = current

        saveToStorage(current)
        onSessionChanged?(current)
    }
}

public extension SessionContext where Model == SessionUser {
    var userId: String? { session?.userId }
    var groupId: String? { session?.groupId }
    var nickname: String? { session?.nickname }
    var profileImageURL: String? { session?.profileImageURL }
    var hasGroup: Bool { groupId != nil }
}

*/
