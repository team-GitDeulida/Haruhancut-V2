//
//  Component.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Item을 UIView로 생성하고 렌더링하는 선언형 UI 단위입니다.
///
/// Item은 Content가 표시할 상태와 안정적인 ID를 함께 표현합니다.
/// 실제 화면 객체는 `Content`이며 Component는 Content를 생성하고
/// Item을 반영하는 책임만 가집니다.
public protocol Component: CompositionalLayoutSizeable {

    /// Content가 표시할 값 타입입니다.
    ///
    /// `Identifiable`의 ID는 Diffable Data Source의 항목 식별에 사용하고,
    /// `Equatable`은 같은 ID의 표시 상태가 바뀌었는지 판단할 때 사용합니다.
    associatedtype Item: Identifiable & Equatable
    
    /// Component가 생성하고 갱신하는 실제 UIView 타입입니다.
    associatedtype Content: UIView

    /// Content에 표시할 현재 Item입니다.
    var item: Item { get }
    
    /// 재사용 가능한 실제 UIView를 생성합니다.
    ///
    /// - Returns: Component의 상태를 표시할 UIView.
    @MainActor
    func createContent() -> Content
    
    /// 현재 Component 상태를 UIView에 반영합니다.
    ///
    /// - Parameters:
    ///   - context: 이번 render의 환경과 작업 수명.
    ///   - content: 새로 생성했거나 재사용한 UIView.
    @MainActor
    func render(
        context: ComponentContext,
        content: Content
    )
}

/// Component를 직접 렌더링할 때 사용하는 편의 API를 제공합니다.
public extension Component {
    
    /// 호출부에서 `content`, `context` label 순서로 렌더링합니다.
    ///
    /// 이 overload는 두 label 순서를 모두 지원하며 protocol 구현 계약은
    /// 원본 선언 순서를 유지합니다.
    @MainActor
    func render(
        content: Content,
        context: ComponentContext
    ) {
        render(context: context, content: content)
    }
}
