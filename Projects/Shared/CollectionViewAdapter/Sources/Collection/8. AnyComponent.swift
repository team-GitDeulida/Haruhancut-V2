//
//  AnyComponent.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

@MainActor
public struct AnyComponent:
    CellItemModelType,
    CompositionalLayoutSizeable {
    
    /// 원본 Component의 안정적인 식별자입니다.
    public let identifier: AnyHashable
    
    /// 원본 Component의 렌더링 버전입니다.
    public let contentVersion: AnyHashable
    
    /// 원본 Component의 self-sizing 추정 높이입니다.
    public let estimatedHeight: CGFloat
    
    /// Concrete Component 타입별 generic cell container 클래스입니다.
    let cellContainerType: AnyClass
    
    /// UIKit reusable container 등록에 사용하는 Component 타입 기반 키입니다.
    let reuseKey: String
    
    public let boxedComponent: Any
    
    /// Concrete Component를 type erase합니다.
    ///
    /// - Parameter component: 저장할 Component 값.
    public init<C: Component>(_ component: C) {
        identifier = component.identifier
        contentVersion = component.contentVersion
        estimatedHeight = component.estimatedHeight
        cellContainerType = ContainerCell<C>.self
        reuseKey = String(reflecting: C.self)
        boxedComponent = component
    }
    
    /// 원본 Component를 요청한 concrete 타입으로 복원합니다.
    func component<C: Component>(
        as componentType: C.Type
    ) -> C? {
        boxedComponent as? C
    }
}
