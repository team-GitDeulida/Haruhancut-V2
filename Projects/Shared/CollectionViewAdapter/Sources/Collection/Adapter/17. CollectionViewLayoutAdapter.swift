//
//  CollectionViewLayoutAdapter.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Section model과 Compositional Layout section provider를 연결합니다.
///
/// KarrotListKit의 `CollectionViewLayoutAdapter`와 같은 역할입니다.
/// 사용자가 `UICollectionViewCompositionalLayout`을 직접 만들고 싶을 때
/// 이 객체의 `sectionLayout`을 section provider로 전달합니다.
///
/// 동일한 인스턴스를 `CollectionViewAdapter`에도 전달해야 bind된 최신
/// Section 정보로 layout을 생성할 수 있습니다.
@MainActor
public final class CollectionViewLayoutAdapter {
    private var sections: [ResolvedSection] = []
    private var sectionsByIdentifier:
        [AnyHashable: ResolvedSection] = [:]

    /// 가로 Section의 현재 거리 정보를 Adapter에 전달합니다.
    var orthogonalSectionDidScroll:
        (
            AnyHashable,
            CollectionViewSectionScrollMetrics
        ) -> Void = { _, _ in }

    /// 현재 bind된 Section에 대응하는 Compositional Layout provider입니다.
    ///
    /// - Important: 이 provider로 layout을 만든 뒤 같은
    ///   `CollectionViewLayoutAdapter`를 `CollectionViewAdapter`에
    ///   주입해야 합니다.
    public var sectionLayout:
        (
            Int,
            NSCollectionLayoutEnvironment
        ) -> NSCollectionLayoutSection?
    {
        { [weak self] sectionIndex, _ in
            guard
                let self,
                self.sections.indices.contains(sectionIndex)
            else {
                return nil
            }

            let resolvedSection =
                self.sections[sectionIndex]
            let layoutSection =
                resolvedSection.makeLayoutSection()

            guard
                resolvedSection.reachedEnd != nil,
                resolvedSection.layout
                    .supportsOrthogonalReachedEnd
            else {
                return layoutSection
            }

            let sectionIdentifier =
                resolvedSection.identifier
            let existingHandler =
                layoutSection
                    .visibleItemsInvalidationHandler
            layoutSection
                .visibleItemsInvalidationHandler = {
                    [weak self]
                    visibleItems,
                    contentOffset,
                    environment in
                    existingHandler?(
                        visibleItems,
                        contentOffset,
                        environment
                    )
                    self?.handleOrthogonalScroll(
                        sectionIdentifier:
                            sectionIdentifier,
                        contentOffset:
                            contentOffset,
                        viewportWidth:
                            environment.container
                                .effectiveContentSize
                                .width
                    )
                }
            return layoutSection
        }
    }

    /// 빈 layout adapter를 만듭니다.
    public init() {}

    func updateSections(
        _ sections: [ResolvedSection]
    ) {
        self.sections = sections
        sectionsByIdentifier = Dictionary(
            uniqueKeysWithValues: sections.map {
                ($0.identifier, $0)
            }
        )
    }

    /// 가로 Section의 offset을 거리 정보로 바꿔 Adapter에 전달합니다.
    ///
    /// 별도 메서드로 분리해 UIKit handler뿐 아니라 회귀 테스트에서도 같은
    /// 거리 계산과 전달 경로를 사용할 수 있습니다.
    func handleOrthogonalScroll(
        sectionIdentifier: AnyHashable,
        contentOffset: CGPoint,
        viewportWidth: CGFloat
    ) {
        guard
            let section =
                sectionsByIdentifier[
                    sectionIdentifier
                ],
            section.reachedEnd != nil,
            let metrics =
                section.layout
                    .makeOrthogonalScrollMetrics(
                        itemCount:
                            section.items.count,
                        viewportWidth:
                            viewportWidth,
                        contentOffsetX:
                            contentOffset.x
                    )
        else {
            return
        }

        orthogonalSectionDidScroll(
            sectionIdentifier,
            metrics
        )
    }
}
