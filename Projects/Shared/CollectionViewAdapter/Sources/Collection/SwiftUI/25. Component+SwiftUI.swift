//
//  25. Component+SwiftUI.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import SwiftUI
import UIKit

/// 하나의 Component를 직접 표시하는 UIKit host view입니다.
///
/// Collection view container와 동일하게 Content는 한 번만 만들고 Component가
/// 바뀔 때 `render`만 다시 호출합니다.
@MainActor
public final class UIComponentView<C: Component>: UIView {
    private let content: C.Content
    private var componentContext: ComponentContext?

    /// 표시할 Component로 host view를 만듭니다.
    ///
    /// - Parameter component: 최초 표시할 Component.
    public init(component: C) {
        content = component.createContent()
        super.init(frame: .zero)

        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            content.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            content.topAnchor.constraint(
                equalTo: topAnchor
            ),
            content.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
        ])
        update(component: component)
    }

    /// Storyboard와 nib 기반 초기화는 지원하지 않습니다.
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    /// 기존 Content에 최신 Component 상태를 반영합니다.
    ///
    /// - Parameter component: 새로 렌더링할 Component 값.
    public func update(component: C) {
        componentContext?.cancel()
        let context = ComponentContext { [weak self] in
            self?.invalidateIntrinsicContentSize()
            self?.setNeedsLayout()
        }
        componentContext = context
        component.render(
            content: content,
            context: context
        )
        invalidateIntrinsicContentSize()
    }

    /// Host가 화면에서 사라질 때 render 단위 작업을 정리합니다.
    public func contentDidEndDisplay() {
        componentContext?.cancel()
    }

    /// Content의 Auto Layout fitting 결과를 host view의 고유 크기로 반환합니다.
    public override var intrinsicContentSize: CGSize {
        content.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        )
    }
}

/// SwiftUI와 `UIComponentView` 사이의 약한 참조를 보관합니다.
@MainActor
public final class ComponentViewProxy<C: Component>:
    ObservableObject
{
    /// 현재 SwiftUI hierarchy가 표시하는 UIKit host view입니다.
    public fileprivate(set) weak var uiView:
        UIComponentView<C>?

    /// 빈 proxy를 만듭니다.
    public init() {}
}

/// Component를 SwiftUI에서 표시할 수 있게 만드는 `UIViewRepresentable`입니다.
@MainActor
public struct ComponentRepresenting<C: Component>:
    UIViewRepresentable
{
    /// `UIViewRepresentable`이 관리하는 UIKit view 타입입니다.
    public typealias UIViewType = UIComponentView<C>

    private let component: C
    private let proxy: ComponentViewProxy<C>

    /// SwiftUI bridge를 만듭니다.
    ///
    /// - Parameters:
    ///   - component: 표시할 Component.
    ///   - proxy: 생성된 UIKit host를 추적할 proxy.
    public init(
        component: C,
        proxy: ComponentViewProxy<C>
    ) {
        self.component = component
        self.proxy = proxy
    }

    /// 별도 proxy가 필요하지 않은 SwiftUI bridge를 만듭니다.
    ///
    /// - Parameter component: 표시할 Component.
    public init(component: C) {
        self.component = component
        proxy = ComponentViewProxy()
    }

    /// 최초 UIKit host view를 생성합니다.
    public func makeUIView(
        context: Context
    ) -> UIComponentView<C> {
        let view = UIComponentView(component: component)
        proxy.uiView = view
        return view
    }

    /// SwiftUI 상태 변경을 기존 UIKit Content에 렌더링합니다.
    public func updateUIView(
        _ uiView: UIComponentView<C>,
        context: Context
    ) {
        proxy.uiView = uiView
        uiView.update(component: component)
    }

    /// SwiftUI hierarchy에서 제거된 host의 작업을 정리합니다.
    public static func dismantleUIView(
        _ uiView: UIComponentView<C>,
        coordinator: Void
    ) {
        uiView.contentDidEndDisplay()
    }
}

/// Component를 SwiftUI `View` 문법으로 노출하는 얇은 wrapper입니다.
@MainActor
public struct ComponentView<C: Component>: View {
    private let component: C

    /// SwiftUI에서 표시할 Component를 받습니다.
    ///
    /// - Parameter component: 표시할 Component.
    public init(_ component: C) {
        self.component = component
    }

    /// UIKit Component를 표시하는 SwiftUI body입니다.
    public var body: some View {
        ComponentRepresenting(component: component)
    }
}

/// SwiftUI `View`를 함께 채택한 Component에 기본 body를 제공합니다.
public extension Component where Self: View {
    /// `Component & View` 타입의 기본 SwiftUI body입니다.
    @MainActor
    var body: some View {
        ComponentView(self)
    }
}

extension OnTouchModifier: View where Wrapped: View {}
extension OnButtonTapModifier: View where Wrapped: View {}
extension OnToggleModifier: View where Wrapped: View {}
