//
//  27. OnButtonTapModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

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
    public init(wrapped: Wrapped, action: @escaping (Wrapped.Content) -> Void) {
        self.wrapped = wrapped
        self.action = action
    }

    /// 원본을 렌더링한 뒤 버튼 이벤트를 현재 render 수명에 연결합니다.
    @MainActor
    public func render(context: ComponentContext, content: Wrapped.Content) {
        wrapped.render(content: content, context: context)

        let observation = content.buttonTapEvent.observe { [weak content] in
            guard let content else { return }
            action(content)
        }
        context.cancellationBag.store(observation)
    }
}

extension OnButtonTapModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

/// `ContainsButton` Content에 버튼 처리 modifier를 추가합니다.
public extension Component where Content: ContainsButton {
    /// Content가 필요 없는 간단한 버튼 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 버튼이 눌렸을 때 실행할 동작.
    /// - Returns: 버튼 동작이 합성된 Component.
    func onButtonTap(_ action: @escaping () -> Void) -> OnButtonTapModifier<Self> {
        OnButtonTapModifier(wrapped: self) { _ in
            action()
        }
    }

    /// Content 내부 버튼의 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 버튼이 눌렸을 때 실행할 동작.
    /// - Returns: 버튼 동작이 합성된 Component.
    func onButtonTap(_ action: @escaping (Content) -> Void) -> OnButtonTapModifier<Self> {
        OnButtonTapModifier(wrapped: self, action: action)
    }
}
