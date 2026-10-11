//
//  OnLongPressModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// `LongPressable` Content의 길게 누르기 이벤트를 처리하는 modifier입니다.
public struct OnLongPressModifier<Wrapped: Component>: ComponentModifier
where Wrapped.Content: LongPressable {
    /// 감싸는 원본 Component입니다.
    public let wrapped: Wrapped

    /// Long press로 인식하기까지 필요한 시간입니다.
    public let minimumDuration: TimeInterval

    /// 길게 누르기를 처리할지 여부입니다. `false`면 modifier를 붙이지 않은 것처럼 동작합니다.
    public let isEnabled: Bool

    private let modifierID = UUID()
    private let action: (Wrapped.Content) -> Void

    /// 길게 누르기 modifier를 만듭니다.
    ///
    /// - Parameters:
    ///   - wrapped: 감쌀 원본 Component.
    ///   - minimumDuration: Long press로 인식하기까지 필요한 0보다 큰 시간.
    ///   - isEnabled: 길게 누르기를 처리할지 여부.
    ///   - action: Content를 길게 눌렀을 때 실행할 동작.
    public init(
        wrapped: Wrapped,
        minimumDuration: TimeInterval,
        isEnabled: Bool = true,
        action: @escaping (Wrapped.Content) -> Void
    ) {
        precondition(minimumDuration > 0, "minimumDuration은 0보다 커야 합니다.")

        self.wrapped = wrapped
        self.minimumDuration = minimumDuration
        self.isEnabled = isEnabled
        self.action = action
    }

    /// 원본을 렌더링한 뒤 long press 이벤트를 현재 render 수명에 연결합니다.
    ///
    /// - Parameters:
    ///   - context: 이벤트 observation을 보관할 이번 render의 환경과 수명.
    ///   - content: Long press 이벤트를 제공하는 원본 Component Content.
    @MainActor
    public func render(context: ComponentContext, content: Wrapped.Content) {
        wrapped.render(content: content, context: context)

        // 꺼져 있으면 재사용된 Content에 남은 recognizer도 끄고 이벤트를 연결하지 않습니다.
        guard isEnabled else {
            content.disableLongPressHandling()
            return
        }

        content.installLongPressHandlingIfNeeded(minimumDuration: minimumDuration)

        let observation = content.longPressEvent.observe { [weak content] in
            guard let content else {
                return
            }
            action(content)
        }
        context.cancellationBag.store(observation)
    }
}

extension OnLongPressModifier: ComponentUpdateTokenProviding {
    var componentUpdateToken: AnyHashable {
        AnyHashable(modifierID)
    }
}

/// `LongPressable` Content에 길게 누르기 처리 modifier를 추가합니다.
public extension Component where Content: LongPressable {
    /// Content가 필요 없는 간단한 long press 동작을 선언적으로 추가합니다.
    ///
    /// - Parameters:
    ///   - minimumDuration: Long press로 인식하기까지 필요한 0보다 큰 시간.
    ///   - isEnabled: 길게 누르기를 처리할지 여부. 조건에 따라 끌 때 사용합니다.
    ///   - action: Content를 길게 눌렀을 때 실행할 동작.
    /// - Returns: Long press 동작이 합성된 Component.
    func onLongPress(
        minimumDuration: TimeInterval = 0.5,
        isEnabled: Bool = true,
        _ action: @escaping () -> Void
    ) -> OnLongPressModifier<Self> {
        OnLongPressModifier(
            wrapped: self,
            minimumDuration: minimumDuration,
            isEnabled: isEnabled
        ) { _ in
            action()
        }
    }

    /// Content 전체의 long press 동작을 선언적으로 추가합니다.
    ///
    /// - Parameters:
    ///   - minimumDuration: Long press로 인식하기까지 필요한 0보다 큰 시간.
    ///   - isEnabled: 길게 누르기를 처리할지 여부. 조건에 따라 끌 때 사용합니다.
    ///   - action: 길게 누른 Content를 전달받아 실행할 동작.
    /// - Returns: Long press 동작이 합성된 Component.
    func onLongPress(
        minimumDuration: TimeInterval = 0.5,
        isEnabled: Bool = true,
        _ action: @escaping (Content) -> Void
    ) -> OnLongPressModifier<Self> {
        OnLongPressModifier(
            wrapped: self,
            minimumDuration: minimumDuration,
            isEnabled: isEnabled,
            action: action
        )
    }
}
