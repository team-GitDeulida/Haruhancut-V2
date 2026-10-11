//
//  OnTouchModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// `Touchable` Content의 터치 이벤트를 처리하는 modifier입니다.
public struct OnTouchModifier<Wrapped: Component>: ComponentModifier
where Wrapped.Content: Touchable {
    /// 감싸는 원본 Component입니다.
    public let wrapped: Wrapped

    /// 터치를 처리할지 여부입니다. `false`면 modifier를 붙이지 않은 것처럼 동작합니다.
    public let isEnabled: Bool

    private let modifierID = UUID()
    private let action: (Wrapped.Content) -> Void

    /// 터치 modifier를 만듭니다.
    ///
    /// - Parameters:
    ///   - wrapped: 감쌀 원본 Component.
    ///   - isEnabled: 터치를 처리할지 여부.
    ///   - action: Content가 터치되었을 때 실행할 동작.
    public init(
        wrapped: Wrapped,
        isEnabled: Bool = true,
        action: @escaping (Wrapped.Content) -> Void
    ) {
        self.wrapped = wrapped
        self.isEnabled = isEnabled
        self.action = action
    }

    /// 원본을 렌더링한 뒤 터치 이벤트를 현재 render 수명에 연결합니다.
    ///
    /// - Parameters:
    ///   - context: 이벤트 observation을 보관할 이번 render의 환경과 수명.
    ///   - content: 터치 이벤트를 제공하는 원본 Component Content.
    @MainActor
    public func render(context: ComponentContext, content: Wrapped.Content) {
        // 원본 Component의 UI를 먼저 그립니다.
        wrapped.render(content: content, context: context)

        // 꺼져 있으면 재사용된 Content에 남은 recognizer도 끄고 이벤트를 연결하지 않습니다.
        guard isEnabled else {
            content.disableTouchHandling()
            return
        }

        // 터치 recognizer를 Content에 최초 한 번만 설치합니다.
        content.installTouchHandlingIfNeeded()

        // Content의 터치 이벤트와 사용자가 `.onTouch`에 전달한 closure를
        // 현재 render 수명 동안 연결합니다.
        let observation = content.touchEvent.observe { [weak content] in
            guard let content else { return }
            action(content)
        }

        // 셀 재사용이나 SwiftUI 재렌더링 시 기존 연결을 취소할 수 있도록
        // observation을 현재 ComponentContext에 보관합니다.
        context.cancellationBag.store(observation)
    }
}

extension OnTouchModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

/// `Touchable` Content에 터치 처리 modifier를 추가합니다.
public extension Component where Content: Touchable {
    /// Content가 필요 없는 간단한 터치 동작을 선언적으로 추가합니다.
    ///
    /// - Parameters:
    ///   - isEnabled: 터치를 처리할지 여부. 조건에 따라 끌 때 사용합니다.
    ///   - action: Content가 터치되었을 때 실행할 동작.
    /// - Returns: 터치 동작이 합성된 Component.
    func onTouch(
        isEnabled: Bool = true,
        _ action: @escaping () -> Void
    ) -> OnTouchModifier<Self> {
        OnTouchModifier(wrapped: self, isEnabled: isEnabled) { _ in
            action()
        }
    }

    /// Content 전체의 터치 동작을 선언적으로 추가합니다.
    ///
    /// - Parameters:
    ///   - isEnabled: 터치를 처리할지 여부. 조건에 따라 끌 때 사용합니다.
    ///   - action: Content가 터치되었을 때 실행할 동작.
    /// - Returns: 터치 동작이 합성된 Component.
    func onTouch(
        isEnabled: Bool = true,
        _ action: @escaping (Content) -> Void
    ) -> OnTouchModifier<Self> {
        OnTouchModifier(wrapped: self, isEnabled: isEnabled, action: action)
    }
}
