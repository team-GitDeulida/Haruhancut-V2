//
//  HostingComponent.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 10/11/26.
//

import SwiftUI
import UIKit

/// SwiftUI View로 셀을 그리는 Component입니다.
///
/// `UIHostingConfiguration`으로 만든 View를 Content에 담습니다. 셀 높이는
/// SwiftUI View가 제안받은 너비에서 계산한 높이를 그대로 사용합니다.
///
/// ```swift
/// HostingComponent(item: row) { row in
///     HStack {
///         Text(row.title)
///         Spacer()
///         Image(systemName: row.isOn ? "checkmark.circle.fill" : "circle")
///     }
///     .padding(16)
/// }
/// .onTouch { toggle(row.id) }
/// ```
///
/// - Important: View는 `item`만으로 그립니다. 같은 Item이면 View를 다시 만들지
///   않으므로, Item 밖의 값을 읽는 View는 그 값이 바뀌어도 갱신되지 않습니다.
///   이벤트는 modifier(`.onTouch` 등)로 연결합니다.
public struct HostingComponent<
    Item: Identifiable & Equatable,
    Body: View
>: Component {
    /// Content에 표시할 현재 Item입니다.
    public let item: Item

    /// Compositional Layout이 최초 크기 계산에 사용할 추정 높이입니다.
    public let estimatedHeight: CGFloat

    private let makeBody: (Item) -> Body

    /// SwiftUI View로 그리는 Component를 만듭니다.
    ///
    /// - Parameters:
    ///   - item: View에 표시할 Item.
    ///   - estimatedHeight: 추정 높이. 실제 높이는 SwiftUI View가 정합니다.
    ///   - content: Item으로 SwiftUI View를 만드는 builder.
    public init(
        item: Item,
        estimatedHeight: CGFloat = 44,
        @ViewBuilder content: @escaping (Item) -> Body
    ) {
        self.item = item
        self.estimatedHeight = estimatedHeight
        makeBody = content
    }

    /// SwiftUI View를 담을 Content를 만듭니다.
    @MainActor
    public func createContent() -> HostingContentView<Item, Body> {
        HostingContentView()
    }

    /// Item이 직전에 반영한 값과 다를 때만 SwiftUI View를 다시 만듭니다.
    ///
    /// - Parameters:
    ///   - context: 이번 render의 환경과 작업 수명.
    ///   - content: 새로 생성했거나 재사용한 Content.
    @MainActor
    public func render(
        context _: ComponentContext,
        content: HostingContentView<Item, Body>
    ) {
        // 화면에 다시 표시되거나 같은 Item으로 다시 bind되면 그리지 않습니다.
        guard content.renderedItem != item else {
            return
        }
        let item = item
        let makeBody = makeBody
        content.update(
            UIHostingConfiguration {
                makeBody(item)
            }
            // 셀 여백은 SwiftUI View에서 직접 정합니다.
            .margins(.all, 0)
        )
        content.renderedItem = item
    }
}

/// `HostingComponent`의 SwiftUI View를 담는 Content입니다.
///
/// 직접 만들지 않습니다. `Touchable`, `Pressable`, `LongPressable`을
/// 채택하므로 `.onTouch`, `.pressedEffect`, `.onLongPress`를 쓸 수 있습니다.
public final class HostingContentView<
    Item: Identifiable & Equatable,
    Body: View
>:
    UIView,
    Touchable,
    Pressable,
    LongPressable
{
    /// 마지막으로 SwiftUI View를 만든 Item입니다.
    var renderedItem: Item?

    private var hostedView: (UIView & UIContentView)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }
}

extension HostingContentView {
    /// 새 configuration을 반영합니다. 처음에는 hosting view를 만들어 꽉 채웁니다.
    ///
    /// - Parameter configuration: 표시할 SwiftUI View를 담은 configuration.
    func update(
        _ configuration: UIHostingConfiguration<Body, EmptyView>
    ) {
        if let hostedView {
            hostedView.configuration = configuration
            return
        }

        let view = configuration.makeContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        hostedView = view
    }
}
