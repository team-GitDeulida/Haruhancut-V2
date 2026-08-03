//
//  CollectionSectionLayoutContext.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Layout 비교에 사용하는 방향별 inset 값입니다.
private struct CollectionLayoutInsetsSignature:
    Equatable
{
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    /// 방향별 inset을 비교 가능한 값 묶음으로 변환합니다.
    ///
    /// - Parameter insets: 보관할 방향성 inset.
    init(_ insets: NSDirectionalEdgeInsets) {
        top = insets.top
        leading = insets.leading
        bottom = insets.bottom
        trailing = insets.trailing
    }
}

/// 기본 제공 layout의 설정과 custom layout 인스턴스를 식별합니다.
private enum CollectionSectionLayoutKindSignature:
    Equatable
{
    case custom(UUID)
    case verticalList(
        estimatedRowHeight: CGFloat?,
        spacing: CGFloat,
        contentInsets:
            CollectionLayoutInsetsSignature
    )
    case grid(
        columns: Int,
        estimatedRowHeight: CGFloat,
        interItemSpacing: CGFloat,
        lineSpacing: CGFloat,
        contentInsets:
            CollectionLayoutInsetsSignature
    )
    case horizontalCarousel(
        itemWidth: CGFloat,
        estimatedHeight: CGFloat,
        spacing: CGFloat,
        behavior: Int,
        contentInsets:
            CollectionLayoutInsetsSignature
    )
}

/// 가로 Section의 끝 접근 판단에 필요한 거리 정보입니다.
struct CollectionViewSectionScrollMetrics {
    /// 현재 화면에 표시되는 가로 viewport 길이입니다.
    let viewportLength: CGFloat

    /// 현재 viewport 끝과 Section content 끝 사이의 남은 거리입니다.
    let remainingDistance: CGFloat
}

/// Custom section layout 생성 시 제공되는 읽기 전용 정보입니다.
public struct CollectionSectionLayoutContext {
    /// 현재 section의 item 개수입니다.
    public let itemCount: Int

    /// 현재 section Component 중 가장 큰 추정 높이입니다.
    public let maximumEstimatedItemHeight: CGFloat

    /// Custom layout 생성에 사용할 Section 정보를 만듭니다.
    ///
    /// - Parameters:
    ///   - itemCount: 현재 Section에 포함된 item 수.
    ///   - maximumEstimatedItemHeight: Item 중 가장 큰 추정 높이.
    init(
        itemCount: Int,
        maximumEstimatedItemHeight: CGFloat
    ) {
        self.itemCount = itemCount
        self.maximumEstimatedItemHeight =
            maximumEstimatedItemHeight
    }
}

/// 하나의 section을 만드는 Compositional Layout 전략입니다.
///
/// 항목의 크기 정보를
/// `UICollectionViewCompositionalLayout` section provider로 변환합니다.
@MainActor
public struct CollectionSectionLayout {
    private let makeLayout:
        (CollectionSectionLayoutContext) ->
        NSCollectionLayoutSection

    private let kindSignature:
        CollectionSectionLayoutKindSignature

    private var sectionContentInsets:
        NSDirectionalEdgeInsets?
    private var headerPinToVisibleBounds = false
    private var footerPinToVisibleBounds = false

    var pinsHeaderToVisibleBounds: Bool {
        headerPinToVisibleBounds
    }

    var pinsFooterToVisibleBounds: Bool {
        footerPinToVisibleBounds
    }

    /// Section 단위 끝 접근 감지를 기본 제공하는 가로 layout인지 나타냅니다.
    var supportsOrthogonalReachedEnd: Bool {
        if case .horizontalCarousel = kindSignature {
            return true
        }
        return false
    }

    /// Custom Compositional Layout section 전략을 만듭니다.
    ///
    /// Adapter가 header와 footer boundary supplementary item을 나중에
    /// 합성하므로 클로저에서는 일반 item/group/section만 구성합니다.
    ///
    /// - Parameter makeLayout: Section 정보를 받아 layout section을 만드는
    ///   클로저.
    public init(
        _ makeLayout: @escaping (
            CollectionSectionLayoutContext
        ) -> NSCollectionLayoutSection
    ) {
        kindSignature = .custom(UUID())
        self.makeLayout = makeLayout
    }

    /// 비교 가능한 기본 layout 설정과 생성 동작을 함께 보관합니다.
    private init(
        kindSignature:
            CollectionSectionLayoutKindSignature,
        makeLayout: @escaping (
            CollectionSectionLayoutContext
        ) -> NSCollectionLayoutSection
    ) {
        self.kindSignature = kindSignature
        self.makeLayout = makeLayout
    }

    /// Section content와 section 경계 사이의 여백을 설정합니다.
    ///
    /// KarrotListKit의 `withSectionContentInsets(_:)`와 같은 역할입니다.
    /// 세로 목록뿐 아니라 grid, carousel, custom layout에도 동일하게
    /// 적용됩니다. Section마다 다른 값을 지정할 수 있습니다.
    ///
    /// - Parameter insets: Section에 적용할 방향성 내부 여백.
    /// - Returns: Section 여백이 반영된 새 layout 값.
    public func withSectionContentInsets(
        _ insets: NSDirectionalEdgeInsets
    ) -> Self {
        var copy = self
        copy.sectionContentInsets = insets
        return copy
    }

    /// Header를 collection view의 visible bounds에 고정할지 설정합니다.
    ///
    /// Header의 UI 내용은 `withHeader(_:)`가 담당하고, 스크롤에 따른 배치
    /// 동작은 section layout이 담당합니다.
    ///
    /// - Parameter pinToVisibleBounds: `true`이면 header를 상단에 고정합니다.
    /// - Returns: Header 고정 설정이 반영된 새 layout 값.
    public func withHeaderPinToVisibleBounds(
        _ pinToVisibleBounds: Bool
    ) -> Self {
        var copy = self
        copy.headerPinToVisibleBounds =
            pinToVisibleBounds
        return copy
    }

    /// Footer를 collection view의 visible bounds에 고정할지 설정합니다.
    ///
    /// - Parameter pinToVisibleBounds: `true`이면 footer를 하단에 고정합니다.
    /// - Returns: Footer 고정 설정이 반영된 새 layout 값.
    public func withFooterPinToVisibleBounds(
        _ pinToVisibleBounds: Bool
    ) -> Self {
        var copy = self
        copy.footerPinToVisibleBounds =
            pinToVisibleBounds
        return copy
    }

    /// 세로 한 줄 목록을 만듭니다.
    ///
    /// - Parameters:
    ///   - estimatedRowHeight: 명시할 self-sizing 추정 높이. `nil`이면 현재
    ///     section Component의 가장 큰 `estimatedHeight`를 사용합니다.
    ///   - spacing: 행 사이 간격.
    ///   - contentInsets: Section 내부 여백.
    /// - Returns: 세로 목록 layout 전략.
    public static func verticalList(
        estimatedRowHeight: CGFloat? = nil,
        spacing: CGFloat = 0,
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        Self(
            kindSignature: .verticalList(
                estimatedRowHeight:
                    estimatedRowHeight,
                spacing: spacing,
                contentInsets:
                    CollectionLayoutInsetsSignature(
                        contentInsets
                    )
            )
        ) { context in
            let height = estimatedRowHeight
                ?? context.maximumEstimatedItemHeight
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(max(1, height))
            )
            let item = NSCollectionLayoutItem(
                layoutSize: itemSize
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: itemSize,
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(
                group: group
            )
            section.interGroupSpacing = spacing
            section.contentInsets = contentInsets
            return section
        }
    }

    /// 같은 너비의 열로 구성된 self-sizing grid를 만듭니다.
    ///
    /// - Parameters:
    ///   - columns: 한 행에 배치할 열 수.
    ///   - estimatedRowHeight: 행의 self-sizing 추정 높이.
    ///   - interItemSpacing: 같은 행 item 사이 간격.
    ///   - lineSpacing: 행 사이 간격.
    ///   - contentInsets: Section 내부 여백.
    /// - Returns: Grid layout 전략.
    public static func grid(
        columns: Int,
        estimatedRowHeight: CGFloat = 100,
        interItemSpacing: CGFloat = 0,
        lineSpacing: CGFloat = 0,
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        precondition(
            columns > 0,
            "grid columns는 1 이상이어야 합니다."
        )

        return Self(
            kindSignature: .grid(
                columns: columns,
                estimatedRowHeight:
                    estimatedRowHeight,
                interItemSpacing:
                    interItemSpacing,
                lineSpacing: lineSpacing,
                contentInsets:
                    CollectionLayoutInsetsSignature(
                        contentInsets
                    )
            )
        ) { _ in
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(
                    max(1, estimatedRowHeight)
                )
            )
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(
                        1 / CGFloat(columns)
                    ),
                    heightDimension: .estimated(
                        max(1, estimatedRowHeight)
                    )
                )
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing =
                .fixed(interItemSpacing)
            let section = NSCollectionLayoutSection(
                group: group
            )
            section.interGroupSpacing = lineSpacing
            section.contentInsets = contentInsets
            return section
        }
    }

    /// 가로로 넘기는 carousel section을 만듭니다.
    ///
    /// - Parameters:
    ///   - itemWidth: Collection view 유효 너비에 대한 item 비율.
    ///   - estimatedHeight: Item의 self-sizing 추정 높이.
    ///   - spacing: Item 사이 간격.
    ///   - behavior: Compositional Layout의 가로 스크롤 방식.
    ///   - contentInsets: Section 내부 여백.
    /// - Returns: Carousel layout 전략.
    public static func horizontalCarousel(
        itemWidth: CGFloat = 0.85,
        estimatedHeight: CGFloat = 160,
        spacing: CGFloat = 12,
        behavior: UICollectionLayoutSectionOrthogonalScrollingBehavior =
            .groupPagingCentered,
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        precondition(
            itemWidth > 0 && itemWidth <= 1,
            "itemWidth는 0보다 크고 1 이하여야 합니다."
        )

        return Self(
            kindSignature: .horizontalCarousel(
                itemWidth: itemWidth,
                estimatedHeight: estimatedHeight,
                spacing: spacing,
                behavior: behavior.rawValue,
                contentInsets:
                    CollectionLayoutInsetsSignature(
                        contentInsets
                    )
            )
        ) { _ in
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(itemWidth),
                heightDimension: .estimated(
                    max(1, estimatedHeight)
                )
            )
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(1)
                )
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(
                group: group
            )
            section.interGroupSpacing = spacing
            section.orthogonalScrollingBehavior = behavior
            section.contentInsets = contentInsets
            return section
        }
    }

    /// Context를 사용해 layout section을 만들고 공통 content inset을 적용합니다.
    ///
    /// - Parameter context: 현재 Section의 item 수와 추정 크기 정보.
    /// - Returns: Boundary item을 추가하기 전의 Compositional Layout section.
    func makeSection(
        context: CollectionSectionLayoutContext
    ) -> NSCollectionLayoutSection {
        let section = makeLayout(context)
        if let sectionContentInsets {
            section.contentInsets =
                sectionContentInsets
        }
        return section
    }

    /// 가로 Carousel의 현재 위치를 끝까지 남은 거리로 변환합니다.
    ///
    /// 기본 제공 Carousel은 하나의 group에 하나의 item을 배치하므로 item
    /// 개수와 group 너비, 간격으로 전체 content 너비를 계산할 수 있습니다.
    /// Custom layout은 배치 규칙을 알 수 없어 Section 단위 거리 감지를
    /// 제공하지 않습니다.
    func makeOrthogonalScrollMetrics(
        itemCount: Int,
        viewportWidth: CGFloat,
        contentOffsetX: CGFloat
    ) -> CollectionViewSectionScrollMetrics? {
        guard
            case let .horizontalCarousel(
                itemWidth,
                _,
                spacing,
                _,
                configuredInsets
            ) = kindSignature
        else {
            return nil
        }

        let viewportLength = max(0, viewportWidth)
        guard viewportLength > 0 else {
            return nil
        }

        let effectiveInsets = sectionContentInsets.map(
            CollectionLayoutInsetsSignature.init
        ) ?? configuredInsets
        let count = max(0, itemCount)
        let groupWidth = viewportLength * itemWidth
        let itemContentWidth =
            CGFloat(count) * groupWidth
        let totalSpacing =
            CGFloat(max(0, count - 1)) * spacing
        let contentWidth =
            effectiveInsets.leading
            + itemContentWidth
            + totalSpacing
            + effectiveInsets.trailing
        let visibleEnd =
            contentOffsetX + viewportLength

        return CollectionViewSectionScrollMetrics(
            viewportLength: viewportLength,
            remainingDistance:
                contentWidth - visibleEnd
        )
    }

    /// 두 Section layout이 같은 배치 결과를 만드는지 비교합니다.
    func isLayoutEquivalent(
        to other: CollectionSectionLayout
    ) -> Bool {
        kindSignature == other.kindSignature
            && sectionContentInsets.map(
                CollectionLayoutInsetsSignature.init
            )
                == other.sectionContentInsets.map(
                    CollectionLayoutInsetsSignature.init
                )
            && headerPinToVisibleBounds
                == other.headerPinToVisibleBounds
            && footerPinToVisibleBounds
                == other.footerPinToVisibleBounds
    }

    /// Header와 footer boundary item에 고정 배치 설정을 적용합니다.
    ///
    /// - Parameters:
    ///   - header: 설정할 header boundary item.
    ///   - footer: 설정할 footer boundary item.
    func applyBoundaryConfiguration(
        header:
            NSCollectionLayoutBoundarySupplementaryItem?,
        footer:
            NSCollectionLayoutBoundarySupplementaryItem?
    ) {
        header?.pinToVisibleBounds =
            headerPinToVisibleBounds
        footer?.pinToVisibleBounds =
            footerPinToVisibleBounds
    }
}
