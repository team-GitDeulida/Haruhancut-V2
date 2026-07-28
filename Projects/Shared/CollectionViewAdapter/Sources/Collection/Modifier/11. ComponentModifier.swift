//
//  ComponentModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// 기존 Component를 감싸 기능을 합성하는 modifier 계약입니다.
///
/// 원본과 같은 Item과 Content를 사용하므로 modifier는 UIView를 새로
/// 감싸지 않고 기존 Content의 생성과 재사용 수명을 그대로 유지합니다.
public protocol ComponentModifier: Component
where
    Wrapped.Content == Content,
    Wrapped.Item == Item
{
    /// modifier가 감싸는 원본 Component 타입입니다.
    associatedtype Wrapped: Component

    /// modifier가 감싸는 원본 Component입니다.
    var wrapped: Wrapped { get }
}

/// 원본 Component의 Item, 높이와 Content 생성을 그대로 전달합니다.
public extension ComponentModifier {
    /// 원본 Component의 Item을 그대로 사용합니다.
    var item: Item {
        wrapped.item
    }

    /// 원본 Component의 추정 높이를 그대로 사용합니다.
    var estimatedHeight: CGFloat {
        wrapped.estimatedHeight
    }

    /// 원본 Component와 동일한 Content를 생성합니다.
    @MainActor
    func createContent() -> Content {
        wrapped.createContent()
    }
}

/// `Pressable` Content에 눌림 시각 효과를 적용하는 modifier입니다.
public struct PressedEffectModifier<Wrapped: Component>:
    ComponentModifier
where Wrapped.Content: Pressable {
    /// 감싸는 원본 Component입니다.
    public let wrapped: Wrapped

    /// 눌렀을 때 Content에 적용할 축소 비율입니다.
    public let scale: CGFloat

    /// 눌림 효과 modifier를 만듭니다.
    ///
    /// - Parameters:
    ///   - wrapped: 감쌀 원본 Component.
    ///   - scale: 0보다 크고 1보다 작은 눌림 상태의 축소 비율.
    public init(
        wrapped: Wrapped,
        scale: CGFloat
    ) {
        self.wrapped = wrapped
        self.scale = scale
    }

    /// 원본을 렌더링한 뒤 Content에 눌림 효과를 한 번만 설치합니다.
    @MainActor
    public func render(
        context: ComponentContext,
        content: Wrapped.Content
    ) {
        wrapped.render(
            content: content,
            context: context
        )
        content.installPressedEffectIfNeeded(
            scale: scale
        )
    }
}

/// `Touchable` Content의 터치 이벤트를 처리하는 modifier입니다.
public struct OnTouchModifier<Wrapped: Component>: ComponentModifier
where Wrapped.Content: Touchable {
    /// 감싸는 원본 Component입니다.
    public let wrapped: Wrapped

    private let modifierID = UUID()
    private let action: (Wrapped.Content) -> Void

    /// 터치 modifier를 만듭니다.
    ///
    /// - Parameters:
    ///   - wrapped: 감쌀 원본 Component.
    ///   - action: Content가 터치되었을 때 실행할 동작.
    public init(
        wrapped: Wrapped,
        action: @escaping (Wrapped.Content) -> Void
    ) {
        self.wrapped = wrapped
        self.action = action
    }

    /// 원본을 렌더링한 뒤 터치 이벤트를 현재 render 수명에 연결합니다.
    @MainActor
    public func render(
        context: ComponentContext,
        content: Wrapped.Content
    ) {
        // 원본 Component의 UI를 먼저 그립니다.
        wrapped.render(content: content, context: context)

        // 터치 recognizer를 Content에 최초 한 번만 설치합니다.
        content.installTouchHandlingIfNeeded()

        // Content의 터치 이벤트와 사용자가 `.onTouch`에 전달한 closure를
        // 현재 render 수명 동안 연결합니다.
        let observation = content.touchEvent.observe {
            [weak content] in
            guard let content else { return }
            action(content)
        }

        // 셀 재사용이나 SwiftUI 재렌더링 시 기존 연결을 취소할 수 있도록
        // observation을 현재 ComponentContext에 보관합니다.
        context.cancellationBag.store(observation)
    }
}

/// `ContainsButton` Content의 버튼 이벤트를 처리하는 modifier입니다.
public struct OnButtonTapModifier<Wrapped: Component>: ComponentModifier
where Wrapped.Content: ContainsButton {
    /// 감싸는 원본 Component입니다.
    public let wrapped: Wrapped

    private let modifierID = UUID()
    private let action: (Wrapped.Content) -> Void

    /// 버튼 modifier를 만듭니다.
    ///
    /// - Parameters:
    ///   - wrapped: 감쌀 원본 Component.
    ///   - action: 내부 버튼이 눌렸을 때 실행할 동작.
    public init(
        wrapped: Wrapped,
        action: @escaping (Wrapped.Content) -> Void
    ) {
        self.wrapped = wrapped
        self.action = action
    }

    /// 원본을 렌더링한 뒤 버튼 이벤트를 현재 render 수명에 연결합니다.
    @MainActor
    public func render(
        context: ComponentContext,
        content: Wrapped.Content
    ) {
        wrapped.render(content: content, context: context)

        let observation = content.buttonTapEvent.observe {
            [weak content] in
            guard let content else { return }
            action(content)
        }
        context.cancellationBag.store(observation)
    }
}

/// `ContainsSwitch` Content의 토글 이벤트를 처리하는 modifier입니다.
public struct OnToggleModifier<Wrapped: Component>: ComponentModifier
where Wrapped.Content: ContainsSwitch {
    /// 감싸는 원본 Component입니다.
    public let wrapped: Wrapped

    private let modifierID = UUID()
    private let action: (Wrapped.Content, Bool) -> Void

    /// 토글 modifier를 만듭니다.
    ///
    /// - Parameters:
    ///   - wrapped: 감쌀 원본 Component.
    ///   - action: 스위치의 새 값과 함께 실행할 동작.
    public init(
        wrapped: Wrapped,
        action: @escaping (Wrapped.Content, Bool) -> Void
    ) {
        self.wrapped = wrapped
        self.action = action
    }

    /// 원본을 렌더링한 뒤 토글 이벤트를 현재 render 수명에 연결합니다.
    @MainActor
    public func render(
        context: ComponentContext,
        content: Wrapped.Content
    ) {
        wrapped.render(content: content, context: context)

        let observation = content.switchToggleEvent.observe {
            [weak content] isOn in
            guard let content else { return }
            action(content, isOn)
        }
        context.cancellationBag.store(observation)
    }
}

extension OnTouchModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

extension OnButtonTapModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

extension OnToggleModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

private struct PressedEffectUpdateToken:
    Hashable
{
    let wrappedToken: AnyHashable?
    let scale: CGFloat
}

extension PressedEffectModifier:
    ComponentUpdateTokenProviding
{
    var componentUpdateToken: AnyHashable {
        AnyHashable(
            PressedEffectUpdateToken(
                wrappedToken:
                    (
                        wrapped as?
                            any ComponentUpdateTokenProviding
                    )?
                    .componentUpdateToken,
                scale: scale
            )
        )
    }
}

/// `Pressable` Content에 눌림 시각 효과 modifier를 추가합니다.
public extension Component where Content: Pressable {
    /// Content를 누르는 동안 축소하고 터치가 끝나면 원래 크기로 복원합니다.
    ///
    /// - Parameter scale: 0보다 크고 1보다 작은 눌림 상태의 축소 비율.
    /// - Returns: 눌림 효과가 합성된 Component.
    func pressedEffect(
        scale: CGFloat = 0.97
    ) -> PressedEffectModifier<Self> {
        PressedEffectModifier(
            wrapped: self,
            scale: scale
        )
    }
}

/// `Touchable` Content에 터치 처리 modifier를 추가합니다.
public extension Component where Content: Touchable {
    /// Content가 필요 없는 간단한 터치 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: Content가 터치되었을 때 실행할 동작.
    /// - Returns: 터치 동작이 합성된 Component.
    func onTouch(
        _ action: @escaping () -> Void
    ) -> OnTouchModifier<Self> {
        OnTouchModifier(wrapped: self) { _ in
            action()
        }
    }

    /// Content 전체의 터치 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: Content가 터치되었을 때 실행할 동작.
    /// - Returns: 터치 동작이 합성된 Component.
    func onTouch(
        _ action: @escaping (Content) -> Void
    ) -> OnTouchModifier<Self> {
        OnTouchModifier(wrapped: self, action: action)
    }
}

/// `ContainsButton` Content에 버튼 처리 modifier를 추가합니다.
public extension Component where Content: ContainsButton {
    /// Content가 필요 없는 간단한 버튼 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 버튼이 눌렸을 때 실행할 동작.
    /// - Returns: 버튼 동작이 합성된 Component.
    func onButtonTap(
        _ action: @escaping () -> Void
    ) -> OnButtonTapModifier<Self> {
        OnButtonTapModifier(wrapped: self) { _ in
            action()
        }
    }

    /// Content 내부 버튼의 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 버튼이 눌렸을 때 실행할 동작.
    /// - Returns: 버튼 동작이 합성된 Component.
    func onButtonTap(
        _ action: @escaping (Content) -> Void
    ) -> OnButtonTapModifier<Self> {
        OnButtonTapModifier(wrapped: self, action: action)
    }
}

/// `ContainsSwitch` Content에 토글 처리 modifier를 추가합니다.
public extension Component where Content: ContainsSwitch {
    /// Content가 필요 없는 토글 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 스위치의 새 값과 함께 실행할 동작.
    /// - Returns: 토글 동작이 합성된 Component.
    func onToggle(
        _ action: @escaping (Bool) -> Void
    ) -> OnToggleModifier<Self> {
        OnToggleModifier(wrapped: self) { _, isOn in
            action(isOn)
        }
    }

    /// Content 내부 스위치의 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 스위치의 새 값과 함께 실행할 동작.
    /// - Returns: 토글 동작이 합성된 Component.
    func onToggle(
        _ action: @escaping (Content, Bool) -> Void
    ) -> OnToggleModifier<Self> {
        OnToggleModifier(wrapped: self, action: action)
    }
}
