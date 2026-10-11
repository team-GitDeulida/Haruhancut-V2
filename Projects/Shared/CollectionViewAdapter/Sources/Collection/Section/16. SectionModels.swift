//
//  SectionModels.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// 하나의 collection view section을 표현하는 모델 계약입니다.
///
/// Section의 핵심 계약은 identifier와 item 생성뿐입니다. Header, footer,
/// Compositional Layout 같은 표현 설정은 `withHeader(_:)`,
/// `withFooter(_:)`, `withSectionLayout(_:)` modifier로 분리합니다.
@MainActor
public protocol SectionModelType {
    /// Section을 안정적으로 식별하는 값입니다.
    var identifier: AnyHashable { get }

    /// 현재 상태에서 section의 item Component를 만듭니다.
    ///
    /// - Returns: 선언 순서대로 만들어진 type-erased Component.
    func makeItems() -> [AnyComponent]
}

/// Adapter에 전달할 수 있는 section model 모음의 공통 계약입니다.
@MainActor
public protocol SectionModelsConvertible {
    /// Type-erased section model 모음입니다.
    var sectionModels: SectionModels { get }
}

/// Adapter에 한 번에 bind할 section model 모음입니다.
@MainActor
public struct SectionModels: SectionModelsConvertible {
    let sections: [any SectionModelType]

    /// Section 배열로 model 모음을 만듭니다.
    ///
    /// - Parameter sections: Adapter에 표시할 section.
    public init(_ sections: [any SectionModelType]) {
        self.sections = sections
    }

    /// Result Builder 표기를 호출부에서 숨기고 section을 선언합니다.
    ///
    /// 사용자는 computed property에 `@SectionModelsBuilder`를 붙이지 않고
    /// `SectionModels { ... }` 문법을 사용할 수 있습니다.
    ///
    /// - Parameter content: Lazy section을 만드는 builder.
    public init(
        @SectionModelsBuilder _ content: () -> SectionModels
    ) {
        self = content()
    }

    /// 자기 자신을 type-erased 입력으로 반환합니다.
    public var sectionModels: SectionModels {
        self
    }
}

/// Content 생성을 실제 bind 시점까지 미루는 section입니다.
///
/// Builder 클로저를 저장해 두었다가 `CollectionViewAdapter.bind`가
/// 호출될 때 item을 평가합니다.
///
/// 두 가지 문법을 모두 지원합니다.
///
/// ```swift
/// // modifier로 설정을 덧붙이는 문법
/// LazySection(identifier: "members") { ... }
///     .withHeader(MemberHeaderComponent(), zIndex: 1)
///     .withSectionLayout(.verticalList(estimatedRowHeight: 60))
///
/// // initializer에서 layout과 header를 함께 선언하는 문법
/// LazySection(id: "members", layout: .list(rowHeight: 60)) {
///     ...
/// } header: {
///     MemberHeaderComponent()
/// }
/// ```
@MainActor
public struct LazySection:
    SectionModelType,
    SectionConfigurationProviding
{
    /// Section을 안정적으로 식별하는 값입니다.
    public let identifier: AnyHashable

    private let content: () -> [AnyComponent]

    let sectionConfiguration: SectionConfiguration

    /// Lazy section을 만듭니다.
    ///
    /// - Parameters:
    ///   - identifier: 다른 section과 겹치지 않는 안정적인 ID.
    ///   - content: Item Component를 만드는 builder.
    public init<ID: Hashable>(
        identifier: ID,
        @SectionBuilder content:
            @escaping () -> [AnyComponent]
    ) {
        self.init(
            identifier: AnyHashable(identifier),
            configuration: SectionConfiguration(),
            content: content
        )
    }

    /// Layout을 함께 지정해 lazy section을 만듭니다.
    ///
    /// - Parameters:
    ///   - id: 다른 section과 겹치지 않는 안정적인 ID.
    ///   - layout: Section의 Compositional Layout 전략. `nil`이면 세로 목록입니다.
    ///   - content: Item Component를 만드는 builder.
    public init<ID: Hashable>(
        id: ID,
        layout: CollectionSectionLayout? = nil,
        @SectionBuilder content:
            @escaping () -> [AnyComponent]
    ) {
        self.init(
            identifier: AnyHashable(id),
            configuration: SectionConfiguration(
                layout: layout ?? .verticalList()
            ),
            content: content
        )
    }

    /// Layout과 header를 함께 지정해 lazy section을 만듭니다.
    ///
    /// - Parameters:
    ///   - id: 다른 section과 겹치지 않는 안정적인 ID.
    ///   - layout: Section의 Compositional Layout 전략. `nil`이면 세로 목록입니다.
    ///   - content: Item Component를 만드는 builder.
    ///   - header: Header로 표시할 Component를 만드는 클로저.
    public init<ID: Hashable, Header: Component>(
        id: ID,
        layout: CollectionSectionLayout? = nil,
        @SectionBuilder content:
            @escaping () -> [AnyComponent],
        header: () -> Header
    ) {
        self.init(
            identifier: AnyHashable(id),
            configuration: SectionConfiguration(
                layout: layout ?? .verticalList(),
                header: .header(header())
            ),
            content: content
        )
    }

    /// Layout과 footer를 함께 지정해 lazy section을 만듭니다.
    ///
    /// - Parameters:
    ///   - id: 다른 section과 겹치지 않는 안정적인 ID.
    ///   - layout: Section의 Compositional Layout 전략. `nil`이면 세로 목록입니다.
    ///   - content: Item Component를 만드는 builder.
    ///   - footer: Footer로 표시할 Component를 만드는 클로저.
    public init<ID: Hashable, Footer: Component>(
        id: ID,
        layout: CollectionSectionLayout? = nil,
        @SectionBuilder content:
            @escaping () -> [AnyComponent],
        footer: () -> Footer
    ) {
        self.init(
            identifier: AnyHashable(id),
            configuration: SectionConfiguration(
                layout: layout ?? .verticalList(),
                footer: .footer(footer())
            ),
            content: content
        )
    }

    /// Layout, header와 footer를 함께 지정해 lazy section을 만듭니다.
    ///
    /// - Parameters:
    ///   - id: 다른 section과 겹치지 않는 안정적인 ID.
    ///   - layout: Section의 Compositional Layout 전략. `nil`이면 세로 목록입니다.
    ///   - content: Item Component를 만드는 builder.
    ///   - header: Header로 표시할 Component를 만드는 클로저.
    ///   - footer: Footer로 표시할 Component를 만드는 클로저.
    public init<
        ID: Hashable,
        Header: Component,
        Footer: Component
    >(
        id: ID,
        layout: CollectionSectionLayout? = nil,
        @SectionBuilder content:
            @escaping () -> [AnyComponent],
        header: () -> Header,
        footer: () -> Footer
    ) {
        self.init(
            identifier: AnyHashable(id),
            configuration: SectionConfiguration(
                layout: layout ?? .verticalList(),
                header: .header(header()),
                footer: .footer(footer())
            ),
            content: content
        )
    }

    private init(
        identifier: AnyHashable,
        configuration: SectionConfiguration,
        content: @escaping () -> [AnyComponent]
    ) {
        self.identifier = identifier
        self.content = content
        sectionConfiguration = configuration
    }

    /// 저장한 builder를 평가해 현재 item Component를 만듭니다.
    public func makeItems() -> [AnyComponent] {
        content()
    }
}

@MainActor
struct SectionReachedEndConfiguration {
    let threshold: CollectionViewReachedEndThreshold
    let action: @MainActor () -> Void
}

@MainActor
struct SectionConfiguration {
    var layout: CollectionSectionLayout = .verticalList()
    var header: SupplementaryView?
    var footer: SupplementaryView?
    var reachedEnd: SectionReachedEndConfiguration?
    /// Header를 스크롤 중 고정하고 item 위에 그릴지 여부입니다.
    var pinsHeader = false
}

@MainActor
protocol SectionConfigurationProviding {
    var sectionConfiguration: SectionConfiguration { get }
}

/// Section 핵심 모델에 supplementary와 layout 설정을 덧붙이는 값 wrapper입니다.
///
/// 이 타입을 직접 만들 필요는 없습니다. `SectionModelType`의
/// `withHeader(_:)`, `withFooter(_:)`, `withSectionLayout(_:)`이 생성합니다.
@MainActor
public struct ConfiguredSection<Base: SectionModelType>:
    SectionModelType,
    SectionConfigurationProviding
{
    private let base: Base
    let sectionConfiguration: SectionConfiguration

    /// 원본 Section과 합성할 설정을 보관하는 wrapper를 만듭니다.
    ///
    /// - Parameters:
    ///   - base: Header, footer, layout 설정을 추가할 원본 Section.
    ///   - configuration: 원본 Section에 적용할 설정 값.
    init(
        base: Base,
        configuration: SectionConfiguration
    ) {
        self.base = base
        sectionConfiguration = configuration
    }

    /// 원본 section의 identifier를 그대로 사용합니다.
    public var identifier: AnyHashable {
        base.identifier
    }

    /// 원본 section의 item 생성 규칙을 그대로 사용합니다.
    public func makeItems() -> [AnyComponent] {
        base.makeItems()
    }
}

/// Section에 header, footer와 layout 설정을 합성합니다.
public extension SectionModelType {
    /// 동일한 `Component`를 section header 위치에 배치합니다.
    ///
    /// Header 전용 Component 프로토콜은 없습니다. 이 modifier는 Component를
    /// `SupplementaryView`에 감싸 Section 설정으로만 보관합니다.
    ///
    /// - Parameters:
    ///   - component: Header로 표시할 일반 Component.
    ///   - alignment: Section을 기준으로 한 header 정렬.
    ///   - height: Header 높이. `nil`이면 Component의 추정 높이.
    ///   - extendsBoundary: Header가 Section content 영역을 확장해 별도
    ///     공간을 차지할지 여부. 기본값은 `true`이며, `false`이면
    ///     첫 item 위에 겹칠 수 있습니다.
    ///   - zIndex: 다른 layout 요소와 겹칠 때의 순서.
    /// - Returns: Header 설정을 가진 새 section 값.
    func withHeader<C: Component>(
        _ component: C,
        alignment: NSRectAlignment = .top,
        height: CollectionLayoutDimension? = nil,
        extendsBoundary: Bool = true,
        zIndex: Int = 0
    ) -> ConfiguredSection<Self> {
        var configuration = resolvedConfiguration
        configuration.header = .header(
            component,
            alignment: alignment,
            height: height,
            extendsBoundary: extendsBoundary,
            zIndex: zIndex
        )
        return ConfiguredSection(
            base: self,
            configuration: configuration
        )
    }

    /// 동일한 `Component`를 section footer 위치에 배치합니다.
    ///
    /// - Parameters:
    ///   - component: Footer로 표시할 일반 Component.
    ///   - alignment: Section을 기준으로 한 footer 정렬.
    ///   - height: Footer 높이. `nil`이면 Component의 추정 높이.
    ///   - extendsBoundary: Footer가 Section content 영역을 확장해 별도
    ///     공간을 차지할지 여부. 기본값은 `true`이며, `false`이면
    ///     마지막 item 위에 겹칠 수 있습니다.
    ///   - zIndex: 다른 layout 요소와 겹칠 때의 순서.
    /// - Returns: Footer 설정을 가진 새 section 값.
    func withFooter<C: Component>(
        _ component: C,
        alignment: NSRectAlignment = .bottom,
        height: CollectionLayoutDimension? = nil,
        extendsBoundary: Bool = true,
        zIndex: Int = 0
    ) -> ConfiguredSection<Self> {
        var configuration = resolvedConfiguration
        configuration.footer = .footer(
            component,
            alignment: alignment,
            height: height,
            extendsBoundary: extendsBoundary,
            zIndex: zIndex
        )
        return ConfiguredSection(
            base: self,
            configuration: configuration
        )
    }

    /// Section에 Compositional Layout 전략을 지정합니다.
    ///
    /// - Parameter layout: Item, group, boundary 동작을 만드는 layout 값.
    /// - Returns: Layout 설정을 가진 새 section 값.
    func withSectionLayout(
        _ layout: CollectionSectionLayout
    ) -> ConfiguredSection<Self> {
        var configuration = resolvedConfiguration
        configuration.layout = layout
        return ConfiguredSection(
            base: self,
            configuration: configuration
        )
    }

    /// Header를 스크롤 중 화면 위쪽에 고정합니다.
    ///
    /// `withSectionLayout(_:)`에서 `withHeaderPinToVisibleBounds(true)`를
    /// 지정하고 header에 `zIndex: 1`을 준 것과 같습니다. Layout이나
    /// header를 지정한 순서와 관계없이 적용됩니다.
    ///
    /// - Returns: Header 고정 설정을 가진 새 section 값.
    func pinnedHeader() -> ConfiguredSection<Self> {
        var configuration = resolvedConfiguration
        configuration.pinsHeader = true
        return ConfiguredSection(
            base: self,
            configuration: configuration
        )
    }

    /// 가로 Section의 끝 접근 영역에 진입했을 때 실행할 동작을 설정합니다.
    ///
    /// 현재 Section 단위 끝 접근 감지는 기본 제공
    /// `CollectionSectionLayout.horizontalCarousel`에서 지원합니다.
    /// 같은 영역에 머무르는 동안 한 번만 실행되며, 영역을 벗어났다가 다시
    /// 진입하면 다음 callback을 전달합니다.
    ///
    /// - Parameters:
    ///   - threshold: 가로 Section 끝에서 callback을 시작할 거리.
    ///   - action: 끝 접근 시 실행할 동작.
    /// - Returns: Section 끝 접근 설정을 가진 새 section 값.
    func onReachedEnd(
        threshold:
            CollectionViewReachedEndThreshold =
                .relativeToViewport(1.5),
        perform action:
            @escaping @MainActor () -> Void
    ) -> ConfiguredSection<Self> {
        var configuration = resolvedConfiguration
        configuration.reachedEnd =
            SectionReachedEndConfiguration(
                threshold: threshold,
                action: action
            )
        return ConfiguredSection(
            base: self,
            configuration: configuration
        )
    }
}

extension SectionModelType {
    var resolvedConfiguration: SectionConfiguration {
        (self as? any SectionConfigurationProviding)?
            .sectionConfiguration ?? SectionConfiguration()
    }

    /// Section과 누적된 설정을 Adapter가 사용할 해석 결과로 변환합니다.
    ///
    /// - Returns: Layout, supplementary view와 끝 접근 설정을 포함한 Section 값.
    func resolve() -> ResolvedSection {
        let configuration = resolvedConfiguration
        var layout = configuration.layout
        var header = configuration.header
        if configuration.pinsHeader {
            layout = layout.withHeaderPinToVisibleBounds(true)
            // 고정된 header가 아래로 지나가는 item에 가려지지 않게 합니다.
            if let zIndex = header?.zIndex {
                header?.zIndex = max(zIndex, 1)
            }
        }
        return ResolvedSection(
            identifier: identifier,
            layout: layout,
            items: makeItems(),
            header: header,
            footer: configuration.footer,
            reachedEnd: configuration.reachedEnd
        )
    }
}

/// 여러 `LazySection`을 선언적으로 조립합니다.
///
/// 일반 사용자는 이 attribute를 직접 붙이지 않습니다. `SectionModels {}`와
/// `CollectionViewAdapter.bind {}`의 closure parameter에 적용됩니다.
@resultBuilder
@MainActor
public enum SectionModelsBuilder {
    /// Section model 하나를 builder 배열로 바꿉니다.
    ///
    /// - Parameter expression: Builder에 추가할 concrete Section model.
    public static func buildExpression<S: SectionModelType>(
        _ expression: S
    ) -> [any SectionModelType] {
        [expression]
    }

    /// 여러 표현식을 선언 순서대로 합칩니다.
    ///
    /// - Parameter components: 선언 순서로 전달된 Section model 배열들.
    public static func buildBlock(
        _ components: [any SectionModelType]...
    ) -> [any SectionModelType] {
        components.flatMap { $0 }
    }

    /// `if`의 값이 없을 때 빈 section 배열을 사용합니다.
    ///
    /// - Parameter component: 조건 분기에서 선택적으로 생성된 Section 배열.
    public static func buildOptional(
        _ component: [any SectionModelType]?
    ) -> [any SectionModelType] {
        component ?? []
    }

    /// `if` 분기의 첫 번째 결과를 사용합니다.
    ///
    /// - Parameter component: `if` 조건이 참일 때 생성된 Section 배열.
    public static func buildEither(
        first component: [any SectionModelType]
    ) -> [any SectionModelType] {
        component
    }

    /// `else` 분기의 두 번째 결과를 사용합니다.
    ///
    /// - Parameter component: `else` 분기에서 생성된 Section 배열.
    public static func buildEither(
        second component: [any SectionModelType]
    ) -> [any SectionModelType] {
        component
    }

    /// Swift 표준 `for`가 만든 section 배열을 평탄화합니다.
    ///
    /// - Parameter components: 반복문 각 회차에서 생성된 Section 배열들.
    public static func buildArray(
        _ components: [[any SectionModelType]]
    ) -> [any SectionModelType] {
        components.flatMap { $0 }
    }

    /// Availability 분기의 section을 그대로 사용합니다.
    ///
    /// - Parameter component: 현재 플랫폼에서 사용할 Section 배열.
    public static func buildLimitedAvailability(
        _ component: [any SectionModelType]
    ) -> [any SectionModelType] {
        component
    }

    /// 최종 section 배열을 Adapter 입력 타입으로 감쌉니다.
    ///
    /// - Parameter component: Builder가 조립한 최종 Section 배열.
    /// - Returns: Adapter bind에 전달할 `SectionModels` 값.
    public static func buildFinalResult(
        _ component: [any SectionModelType]
    ) -> SectionModels {
        SectionModels(component)
    }
}

@MainActor
struct ResolvedSection {
    let identifier: AnyHashable
    let layout: CollectionSectionLayout
    let items: [AnyComponent]
    let header: SupplementaryView?
    let footer: SupplementaryView?
    let reachedEnd: SectionReachedEndConfiguration?

    var maximumEstimatedItemHeight: CGFloat {
        items.map(\.estimatedHeight).max() ?? 44
    }

    /// Item과 supplementary 설정을 포함한 UIKit layout section을 만듭니다.
    ///
    /// - Returns: Collection view에 적용할 Compositional Layout section.
    func makeLayoutSection() -> NSCollectionLayoutSection {
        let context = CollectionSectionLayoutContext(
            itemCount: items.count,
            maximumEstimatedItemHeight:
                maximumEstimatedItemHeight
        )
        let section = layout.makeSection(context: context)
        let headerItem = header?.makeLayoutItem()
        let footerItem = footer?.makeLayoutItem()
        layout.applyBoundaryConfiguration(
            header: headerItem,
            footer: footerItem
        )
        section.boundarySupplementaryItems = [
            headerItem,
            footerItem,
        ].compactMap { $0 }
        return section
    }
}
