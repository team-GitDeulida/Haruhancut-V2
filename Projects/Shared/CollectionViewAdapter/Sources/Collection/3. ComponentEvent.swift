//
//  ComponentEvent.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// `ComponentEvent`에 등록한 관찰을 취소하는 토큰입니다.
///
/// RxSwift의 `Disposable`이 맡던 최소 역할만 제공하며, 외부 라이브러리에
/// 의존하지 않습니다.
@MainActor
public final class ComponentEventObservation {
    
    private var cancellation: (() -> Void)?
    
    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }
    
    /// 관찰을 취소합니다.
    ///
    /// 여러 번 호출해도 실제 취소 동작은 한 번만 실행됩니다.
    public func cancel() {
        let action = cancellation
        cancellation = nil
        action?()
    }
}

/// Component의 사용자 동작을 전달하는 작은 이벤트 스트림입니다.
///
/// 외부 반응형 라이브러리 없이 UI 동작을 전달합니다.
/// 이벤트는 MainActor에서만 구독하고 전달됩니다.
@MainActor
public final class ComponentEvent<Value> {
    
    private var observers: [UUID: (Value) -> Void] = [:]
    
    /// 새로운 빈 이벤트 스트림을 만듭니다.
    public init() {}
    
    /// 이벤트를 관찰합니다.
    ///
    /// - Parameter observer: 값이 전달될 때 호출할 클로저.
    /// - Returns: 관찰을 중단할 때 사용할 토큰.
    @discardableResult
    public func observe(
        _ observer: @escaping (Value) -> Void
    ) -> ComponentEventObservation {
        let id = UUID()
        observers[id] = observer
        
        return ComponentEventObservation { [weak self] in
            self?.observers[id] = nil
        }
    }
    
    /// 현재 등록된 모든 관찰자에게 값을 전달합니다.
    ///
    /// - Parameter value: 전달할 값.
    public func send(_ value: Value) {
        let currentObservers = Array(observers.values)
        currentObservers.forEach { $0(value) }
    }
}
