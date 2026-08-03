//
//  PressedEffectModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// `Pressable` Content에 눌림 시각 효과를 적용하는 modifier입니다.
public struct PressedEffectModifier<Wrapped: Component>: ComponentModifier
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
    public init(wrapped: Wrapped, scale: CGFloat) {
        self.wrapped = wrapped
        self.scale = scale
    }

    /// 원본을 렌더링한 뒤 Content에 눌림 효과를 한 번만 설치합니다.
    ///
    /// - Parameters:
    ///   - context: 이번 render의 환경과 작업 수명.
    ///   - content: 눌림 효과를 설치할 원본 Component Content.
    @MainActor
    public func render(context: ComponentContext, content: Wrapped.Content) {
        wrapped.render(content: content, context: context)
        content.installPressedEffectIfNeeded(scale: scale)
    }
}

private struct PressedEffectUpdateToken: Hashable {
    let wrappedToken: AnyHashable?
    let scale: CGFloat
}

extension PressedEffectModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        let wrappedToken = (wrapped as? any ComponentUpdateTokenProviding)?.componentUpdateToken

        return AnyHashable(
            PressedEffectUpdateToken(
                wrappedToken: wrappedToken,
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
    func pressedEffect(scale: CGFloat = 0.97) -> PressedEffectModifier<Self> {
        PressedEffectModifier(
            wrapped: self,
            scale: scale
        )
    }
}
