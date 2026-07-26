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
    func component<C: Component>(
        as componentType: C.Type
    ) -> C? {
        boxedComponent as? C
    }
}
