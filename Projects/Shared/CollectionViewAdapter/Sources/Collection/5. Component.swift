//
//  Component.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// 상태를 UIView로 생성하고 렌더링하는 선언형 UI 단위입니다.
///
/// `Component`는 `CellItemModelType`과 Compositional Layout용 sizing 계약을
/// 함께 따릅니다. 실제 화면 객체는 `Content`이며 Component는 Content를
/// 생성하고 현재 상태를 반영하는 책임만 가집니다.
@MainActor
public protocol Component:
    CellItemModelType,
    CompositionalLayoutSizeable {
    
    /// Component가 생성하고 갱신하는 실제 UIView 타입입니다.
    associatedtype Content: UIView
    
    /// 재사용 가능한 실제 UIView를 생성합니다.
    ///
    /// - Returns: Component의 상태를 표시할 UIView.
    func createContent() -> Content
    
    /// 현재 Component 상태를 UIView에 반영합니다.
    ///
    /// - Parameters:
    ///   - context: 이번 render의 환경과 작업 수명.
    ///   - content: 새로 생성했거나 재사용한 UIView.
    func render(
        context: ComponentContext,
        content: Content
    )
}

public extension Component {
    
    /// 호출부에서 `content`, `context` label 순서로 렌더링합니다.
    ///
    /// 이 overload는 두 label 순서를 모두 지원하며 protocol 구현 계약은
    /// 원본 선언 순서를 유지합니다.
    func render(
        content: Content,
        context: ComponentContext
    ) {
        render(context: context, content: content)
    }
}

public extension Component where Self: Hashable {
    
    /// Hashable Component의 전체 값을 기본 렌더링 버전으로 사용합니다
    var contentVersion: AnyHashable {
        AnyHashable(self)
    }
}
