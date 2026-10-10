//
//  Session.swift
//  Core
//
//  Created by 김동현 on 1/25/26.
//

import Foundation

/// 로그인 사용자·그룹처럼 앱 전체가 함께 보는 현재 상태를 저장하고 바뀔 때 알리는 계약입니다.
///
/// 값은 저장소에 보관해 앱을 다시 실행해도 복원합니다.
public protocol SessionProtocol {
    /// 세션에 담는 값의 타입입니다. 저장소에 JSON으로 저장할 수 있어야 합니다.
    associatedtype Model: Codable & Equatable & CustomStringConvertible

    /// `update`·`clear`가 불릴 때 새 값(지우면 `nil`)을 받는 클로저입니다.
    typealias SessionChangeHandler = (Model?) -> Void

    /// 현재 값입니다. 없으면 `nil`입니다.
    var session: Model? { get }

    /// 현재 값이 있는지 나타냅니다.
    var hasSession: Bool { get }

    /// 현재 값으로 한 번 바로 호출하고, 이후 `update`·`clear`가 불릴 때마다 호출합니다. 값이 같아도 호출합니다.
    ///
    /// - Returns: `removeObserver(_:)`에 넘길 구독 ID.
    func bind(_ handler: @escaping SessionChangeHandler) -> UUID

    /// `update`·`clear`가 불릴 때마다 호출합니다. 값이 같아도 호출하고, 등록할 때는 호출하지 않습니다.
    ///
    /// - Returns: `removeObserver(_:)`에 넘길 구독 ID.
    func observe(_ handler: @escaping SessionChangeHandler) -> UUID

    /// `bind(_:)`·`observe(_:)`로 등록한 구독을 해제합니다.
    func removeObserver(_ id: UUID)

    /// 값을 바꾸고 저장한 뒤 구독자에게 알립니다.
    func update(_ model: Model)

    /// 현재 값의 한 속성만 바꾸고 저장한 뒤 구독자에게 알립니다. 현재 값이 없으면 아무 일도 하지 않습니다.
    func update<Value>(
        _ keyPath: WritableKeyPath<Model, Value>,
        _ value: Value
    )

    /// 값을 지우고 저장소에서도 삭제한 뒤 구독자에게 `nil`을 알립니다.
    func clear()
}

public final class SessionContext<Model: Codable & Equatable & CustomStringConvertible>: SessionProtocol {
    public typealias SessionChangeHandler = (Model?) -> Void
    private let storage: StorageProtocol
    private let storageKey: String
    private var cached: Model?
    // private var onSessionChanged: SessionChangeHandler?
    // 여려 구독자 지원
    private var observers: [UUID: SessionChangeHandler] = [:]
    
    public init(
        storage: StorageProtocol = UserDefaultsStorage(),
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
        storage.read(storageKey)
    }
    
    func saveToStorage(_ model: Model) {
        do {
            try storage.write(model, to: storageKey)
        } catch {
            // 저장에 실패하면 이전 값이 남지 않도록 지웁니다
            storage.remove(storageKey)
        }
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

