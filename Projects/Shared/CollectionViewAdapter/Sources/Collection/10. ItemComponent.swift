//
//  ItemComponent.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 10/11/26.
//

import ObjectiveC
import UIKit

/// Item 하나를 받아 스스로 그리는 Content View 계약입니다.
///
/// 채택하면 Component 구조체를 따로 만들지 않고 `ItemComponent<Self>`로 바로
/// 사용할 수 있습니다. `apply(_:)`는 직전에 반영한 Item과 다를 때만 호출되므로
/// 같은 값인지 직접 비교하지 않아도 됩니다.
///
/// ```swift
/// final class SettingRowContentView: UIView, ItemContentView {
///     struct Item: Identifiable, Equatable { ... }
///     nonisolated static let estimatedHeight: CGFloat = 52
///     func apply(_ item: Item) { ... }
/// }
///
/// typealias SettingRowComponent = ItemComponent<SettingRowContentView>
/// ```
///
/// 이벤트에 원본 모델이 필요하거나 Component에 Item 밖의 값이 필요하면
/// `Component`를 직접 구현합니다.
public protocol ItemContentView: UIView {
    /// Content가 표시할 값 타입입니다.
    ///
    /// ID는 Diffable Data Source의 항목 식별에, `Equatable`은 같은 ID의
    /// 표시 상태가 바뀌었는지 판단할 때 사용합니다.
    associatedtype Item: Identifiable & Equatable

    /// Compositional Layout이 최초 크기 계산에 사용할 추정 높이입니다.
    ///
    /// 실제 높이는 Content의 Auto Layout으로 정해집니다. Content가 main actor에
    /// 속하므로 `nonisolated static let`으로 선언합니다. 선언하지 않으면 44pt입니다.
    nonisolated static var estimatedHeight: CGFloat { get }

    /// 재사용 가능한 Content를 만듭니다.
    @MainActor
    init()

    /// Item을 화면에 반영합니다.
    ///
    /// 직전에 반영한 Item과 다를 때만 호출됩니다. Cell 재사용으로 다른 Item이
    /// 들어오면 이전 값을 덮어쓰도록 모든 표시 상태를 다시 설정합니다.
    ///
    /// - Parameter item: 표시할 현재 Item.
    @MainActor
    func apply(_ item: Item)
}

public extension ItemContentView {
    /// 별도 지정이 없을 때 사용하는 기본 추정 높이입니다.
    nonisolated static var estimatedHeight: CGFloat { 44 }
}

/// `ItemContentView`를 그대로 Component로 사용하는 generic Component입니다.
///
/// Modifier, Header·Footer, SwiftUI `ComponentView`에서 직접 만든 Component와
/// 똑같이 사용할 수 있습니다. 화면에서는 typealias로 이름을 붙여 씁니다.
///
/// ```swift
/// typealias SettingRowComponent = ItemComponent<SettingRowContentView>
///
/// SettingRowComponent(item: item)
///     .onTouch { ... }
/// ```
public struct ItemComponent<Content: ItemContentView>: Component {
    /// Content에 표시할 현재 Item입니다.
    public let item: Content.Item

    /// Compositional Layout이 최초 크기 계산에 사용할 추정 높이입니다.
    public let estimatedHeight: CGFloat

    /// Item으로 Component를 만듭니다.
    ///
    /// - Parameters:
    ///   - item: Content에 표시할 Item.
    ///   - estimatedHeight: 추정 높이. `nil`이면 `Content.estimatedHeight`입니다.
    public init(
        item: Content.Item,
        estimatedHeight: CGFloat? = nil
    ) {
        self.item = item
        self.estimatedHeight =
            estimatedHeight ?? Content.estimatedHeight
    }

    /// 재사용 가능한 Content를 만듭니다.
    @MainActor
    public func createContent() -> Content {
        Content()
    }

    /// Item이 직전에 반영한 값과 다를 때만 Content에 반영합니다.
    ///
    /// - Parameters:
    ///   - context: 이번 render의 환경과 작업 수명.
    ///   - content: 새로 생성했거나 재사용한 Content.
    @MainActor
    public func render(
        context _: ComponentContext,
        content: Content
    ) {
        // 화면에 다시 표시되거나 같은 Item으로 다시 bind되면 그리지 않습니다.
        guard content.appliedItem != item else {
            return
        }
        content.apply(item)
        content.appliedItem = item
    }
}

/// Content가 마지막으로 반영한 Item을 보관하는 associated object key입니다.
@MainActor
private enum AppliedItemKey {
    static var key: UInt8 = 0
}

private extension ItemContentView {
    /// 마지막으로 `apply(_:)`에 넘긴 Item입니다.
    @MainActor
    var appliedItem: Item? {
        get {
            objc_getAssociatedObject(
                self,
                &AppliedItemKey.key
            ) as? Item
        }
        set {
            objc_setAssociatedObject(
                self,
                &AppliedItemKey.key,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
