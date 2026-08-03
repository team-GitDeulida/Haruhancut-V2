//
//  OnToggleModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

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
    public init(wrapped: Wrapped, action: @escaping (Wrapped.Content, Bool) -> Void) {
        self.wrapped = wrapped
        self.action = action
    }

    /// 원본을 렌더링한 뒤 토글 이벤트를 현재 render 수명에 연결합니다.
    ///
    /// - Parameters:
    ///   - context: 이벤트 observation을 보관할 이번 render의 환경과 수명.
    ///   - content: 토글 이벤트를 제공하는 원본 Component Content.
    @MainActor
    public func render(context: ComponentContext, content: Wrapped.Content) {
        wrapped.render(content: content, context: context)

        let observation = content.switchToggleEvent.observe { [weak content] isOn in
            guard let content else { return }
            action(content, isOn)
        }
        context.cancellationBag.store(observation)
    }
}

extension OnToggleModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

/// `ContainsSwitch` Content에 토글 처리 modifier를 추가합니다.
public extension Component where Content: ContainsSwitch {
    /// Content가 필요 없는 토글 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 스위치의 새 값과 함께 실행할 동작.
    /// - Returns: 토글 동작이 합성된 Component.
    func onToggle(_ action: @escaping (Bool) -> Void) -> OnToggleModifier<Self> {
        OnToggleModifier(wrapped: self) { _, isOn in
            action(isOn)
        }
    }

    /// Content 내부 스위치의 동작을 선언적으로 추가합니다.
    ///
    /// - Parameter action: 스위치의 새 값과 함께 실행할 동작.
    /// - Returns: 토글 동작이 합성된 Component.
    func onToggle(_ action: @escaping (Content, Bool) -> Void) -> OnToggleModifier<Self> {
        OnToggleModifier(wrapped: self, action: action)
    }
}
