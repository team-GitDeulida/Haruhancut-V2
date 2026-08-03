//
//  SectionBuilder.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// `For(of:)` 문법을 제공하는 item 묶음입니다.
///
/// Swift 표준 `for`도 builder에서 지원하지만, 명시적인 반복 표현을
/// 원할 때 사용합니다.
@MainActor
public struct For<Data: RandomAccessCollection> {
    let items: [AnyComponent]

    /// Collection의 각 값으로 item Component를 만듭니다.
    ///
    /// - Parameters:
    ///   - data: 순회할 데이터.
    ///   - content: 각 값에서 item Component를 만드는 builder.
    public init(
        of data: Data,
        @SectionBuilder content:
            (Data.Element) -> [AnyComponent]
    ) {
        items = data.flatMap(content)
    }
}

/// `LazySection`의 item Component만 선언적으로 조립합니다.
///
/// Header와 footer는 item builder에 섞지 않고 Section의
/// `withHeader(_:)`, `withFooter(_:)` modifier로 지정합니다.
@resultBuilder
@MainActor
public enum SectionBuilder {
    /// 일반 Component를 item 하나로 바꿉니다.
    ///
    /// - Parameter expression: Builder에 추가할 concrete Component.
    public static func buildExpression<C: Component>(
        _ expression: C
    ) -> [AnyComponent] {
        [AnyComponent(expression)]
    }

    /// 이미 type erase한 Component를 item 하나로 바꿉니다.
    ///
    /// - Parameter expression: Builder에 추가할 type-erased Component.
    public static func buildExpression(
        _ expression: AnyComponent
    ) -> [AnyComponent] {
        [expression]
    }

    /// `For(of:)`가 만든 item을 builder에 합칩니다.
    ///
    /// - Parameter expression: 반복 builder가 만든 Component 묶음.
    public static func buildExpression<Data: RandomAccessCollection>(
        _ expression: For<Data>
    ) -> [AnyComponent] {
        expression.items
    }

    /// 여러 표현식을 선언 순서대로 합칩니다.
    ///
    /// - Parameter components: 선언 순서로 전달된 Component 배열들.
    public static func buildBlock(
        _ components: [AnyComponent]...
    ) -> [AnyComponent] {
        components.flatMap { $0 }
    }

    /// `if`의 값이 없을 때 빈 item 목록을 사용합니다.
    ///
    /// - Parameter component: 조건 분기에서 선택적으로 생성된 Component 배열.
    public static func buildOptional(
        _ component: [AnyComponent]?
    ) -> [AnyComponent] {
        component ?? []
    }

    /// `if` 분기의 첫 번째 결과를 사용합니다.
    ///
    /// - Parameter component: `if` 조건이 참일 때 생성된 Component 배열.
    public static func buildEither(
        first component: [AnyComponent]
    ) -> [AnyComponent] {
        component
    }

    /// `else` 분기의 두 번째 결과를 사용합니다.
    ///
    /// - Parameter component: `else` 분기에서 생성된 Component 배열.
    public static func buildEither(
        second component: [AnyComponent]
    ) -> [AnyComponent] {
        component
    }

    /// Swift 표준 `for`가 만든 배열을 평탄화합니다.
    ///
    /// - Parameter components: 반복문 각 회차에서 생성된 Component 배열들.
    public static func buildArray(
        _ components: [[AnyComponent]]
    ) -> [AnyComponent] {
        components.flatMap { $0 }
    }

    /// Availability 분기의 item을 그대로 사용합니다.
    ///
    /// - Parameter component: 현재 플랫폼에서 사용할 Component 배열.
    public static func buildLimitedAvailability(
        _ component: [AnyComponent]
    ) -> [AnyComponent] {
        component
    }
}
