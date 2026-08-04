//
//  AnyComponent.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// 이벤트 modifier처럼 Item 외 상태가 바뀔 때 다시 bind하기 위한 내부 계약입니다.
protocol ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable { get }
}

/// 서로 다른 concrete Component를 하나의 타입으로 보관합니다.
///
/// Adapter는 이 값을 사용해 Component의 식별자, 추정 높이와 container
/// 타입을 generic 타입 정보 없이 처리합니다.
public struct AnyComponent: CompositionalLayoutSizeable {
    
    /// 원본 Component의 안정적인 식별자입니다.
    let id: AnyHashable
    
    /// 원본 Component의 self-sizing 추정 높이입니다.
    public let estimatedHeight: CGFloat
    
    /// Concrete Component 타입별 generic cell container 클래스입니다.
    let cellContainerType: AnyClass
    
    /// UIKit reusable container 등록에 사용하는 Component 타입 기반 키입니다.
    let reuseKey: String
    
    let boxedComponent: Any

    private let updateToken: AnyHashable?
    private let isItemEqual: (Any) -> Bool
    
    /// Concrete Component를 type erase합니다.
    ///
    /// - Parameter component: 저장할 Component 값.
    public init<C: Component>(_ component: C) {
        id = AnyHashable(component.item.id)
        estimatedHeight = component.estimatedHeight
        cellContainerType = ContainerCell<C>.self
        reuseKey = String(reflecting: C.self)
        boxedComponent = component
        updateToken =
            (component as? any ComponentUpdateTokenProviding)?
                .componentUpdateToken
        isItemEqual = { boxedComponent in
            guard
                let otherComponent = boxedComponent as? C
            else {
                return false
            }
            return component.item == otherComponent.item
        }
    }

    /// 두 Component가 같은 Content 표시 상태와 내부 연결을 가지는지 비교합니다.
    ///
    /// - Parameter other: 현재 Component와 비교할 다른 type-erased Component.
    /// - Returns: 재사용 key, Item 상태와 modifier 연결 상태가 모두 같으면 `true`.
    func isContentEqual(to other: AnyComponent) -> Bool {
        guard
            reuseKey == other.reuseKey,
            updateToken == other.updateToken
        else {
            return false
        }
        return isItemEqual(other.boxedComponent)
    }
    
    /// 원본 Component를 요청한 concrete 타입으로 복원합니다.
    ///
    /// - Parameter componentType: 복원할 원본 Component의 concrete 타입.
    /// - Returns: 저장한 Component가 요청 타입과 같으면 복원된 값, 아니면 `nil`.
    func component<C: Component>(
        as componentType: C.Type
    ) -> C? {
        boxedComponent as? C
    }
}
