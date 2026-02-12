//
//  Session.swift
//  Core
//
//  Created by 김동현 on 1/25/26.
//

import Foundation

public protocol SessionType {
    associatedtype Model: Codable & Equatable & CustomStringConvertible
    typealias SessionChangeHandler = (Model?) -> Void
    
    var session: Model? { get }
    var hasSession: Bool { get }
    
    func bind(_ handler: @escaping SessionChangeHandler) -> UUID
    func observe(_ handler: @escaping SessionChangeHandler) -> UUID
    func removeObserver(_ id: UUID)
    func update(_ model: Model)
    func update<Value>(
        _ keyPath: WritableKeyPath<Model, Value>,
        _ value: Value
    )
    func clear()
}

public final class SessionContext<Model: Codable & Equatable & CustomStringConvertible>: SessionType {
    public typealias SessionChangeHandler = (Model?) -> Void
    private let storage: UserDefaultsStorageProtocol
    private let storageKey: String
    private var cached: Model?
    // private var onSessionChanged: SessionChangeHandler?
    // 여려 구독자 지원
    private var observers: [UUID: SessionChangeHandler] = [:]
    
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

    @discardableResult
    func bind(_ handler: @escaping SessionChangeHandler) -> UUID {
        let id = observe(handler)
        handler(session)
        return id
    }

    @discardableResult
    func observe(_ handler: @escaping SessionChangeHandler) -> UUID {
        let id = UUID()
        observers[id] = handler
        return id
    }
    
    func removeObserver(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    func update(_ model: Model) {
        cached = model
        saveToStorage(model)
        observers.values.forEach { $0(model) }
    }

    func clear() {
        cached = nil
        storage.remove(storageKey)
        observers.values.forEach { $0(nil) }
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
        observers.values.forEach { $0(current) }
    }
}

