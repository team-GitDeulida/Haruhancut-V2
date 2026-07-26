//
//  CollectionViewAdapter.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Section DSL과 UIKit collection view 사이의 세부 구현을 숨기는 adapter입니다.
///
/// 외부에서는 `bind(_:)`로 section tree만 넘깁니다. 내부에서는
/// Diffable Data Source, generic container 등록, custom
/// Component cell binding, supplementary provider와
/// `CollectionViewLayoutAdapter` 동기화를 관리합니다.
@MainActor
public final class CollectionViewAdapter:
    NSObject
{
    /// Adapter가 관리하는 collection view입니다.
    public private(set) weak var collectionView: UICollectionView?

    /// Section model의 layout 전략을 Compositional Layout에 연결합니다.
    let layoutAdapter: CollectionViewLayoutAdapter

    /// `UICollectionViewDelegate` 공개 callback의 저장소입니다.
    let delegateCallbacks =
        CollectionViewAdapterDelegateCallbacks()

    /// Prefetch 공개 callback의 저장소입니다.
    let prefetchCallbacks =
        CollectionViewAdapterPrefetchCallbacks()

    /// Scroll 위치 기반 공개 callback과 예약 상태의 저장소입니다.
    let scrollCallbacks =
        CollectionViewAdapterScrollCallbacks()

    /// Section별 끝 접근 callback과 전달 상태의 저장소입니다.
    let sectionReachedEndCallbacks =
        CollectionViewAdapterSectionReachedEndCallbacks()

    /// 마지막으로 bind한, layout과 supplementary 설정까지 해석된 Section입니다.
    var sections: [ResolvedSection] = []

    /// Section과 Item 식별자로 Component를 즉시 찾기 위한 조회 저장소입니다.
    var componentsBySectionIdentifier:
        [
            AnyHashable:
                [AnyHashable: AnyComponent]
        ] = [:]

    /// 이미 등록한 cell reuse key입니다.
    var registeredCellReuseKeys: Set<String> = []

    /// 이미 등록한 supplementary view의 kind와 reuse key 조합입니다.
    var registeredSupplementaryReuseKeys: Set<String> = []

    /// Snapshot과 reusable view provider를 관리하는 Diffable Data Source입니다.
    lazy var diffableDataSource:
        AdapterDiffableDataSource = {
            makeDiffableDataSource()
        }()

    /// Adapter가 Compositional Layout까지 만들어 주는 간단한 방식입니다.
    ///
    /// 전달한 collection view의 기존 layout을 교체합니다. Layout
    /// configuration을 직접 제어해야 한다면
    /// `init(collectionView:layoutAdapter:)`를 사용합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Adapter가 관리할 collection view.
    ///   - interSectionSpacing: Header와 footer를 포함한 Section 전체와
    ///     다음 Section 사이의 간격.
    public convenience init(
        collectionView: UICollectionView,
        interSectionSpacing: CGFloat = 0
    ) {
        let layoutAdapter =
            CollectionViewLayoutAdapter()
        let configuration =
            UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing =
            interSectionSpacing

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider:
                layoutAdapter.sectionLayout,
            configuration: configuration
        )
        collectionView.setCollectionViewLayout(
            layout,
            animated: false
        )

        self.init(
            collectionView: collectionView,
            layoutAdapter: layoutAdapter
        )
    }

    /// 사용자가 만든 Compositional Layout을 유지하는 당근식 방식입니다.
    ///
    /// 이 initializer는 collection view의 layout을 교체하지 않습니다.
    /// `layoutAdapter.sectionLayout`로 Compositional Layout을 만든 뒤 동일한
    /// layout adapter 인스턴스를 전달해야 합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 외부에서 Compositional Layout을 설정한
    ///     collection view.
    ///   - layoutAdapter: Layout의 section provider와 Adapter bind를
    ///     연결할 객체.
    public init(
        collectionView: UICollectionView,
        layoutAdapter: CollectionViewLayoutAdapter
    ) {
        self.collectionView = collectionView
        self.layoutAdapter = layoutAdapter
        super.init()

        _ = diffableDataSource
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        layoutAdapter.orthogonalSectionDidScroll = {
            [weak self] sectionIdentifier, metrics in
            self?.triggerSectionReachedEndIfNeeded(
                sectionIdentifier:
                    sectionIdentifier,
                metrics: metrics
            )
        }
    }

    /// Section model을 collection view에 반영합니다.
    ///
    /// 이 메서드는 Rx의 `bind(to:)`가 아닙니다. 입력을 동기적으로 resolve하고
    /// Diffable Data Source snapshot을 적용하는 사용자 정의 API입니다.
    ///
    /// - Parameters:
    ///   - sectionModels: `SectionModels {}`로 만든 section 모음.
    ///   - animatingDifferences: Diffable 변경 애니메이션 사용 여부.
    ///   - completion: Snapshot 반영을 마친 뒤 실행할 동작.
    public func bind(
        _ sectionModels: any SectionModelsConvertible,
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let newSections = sectionModels.sectionModels.sections
            .map { $0.resolve() }
        validate(newSections)
        registerContainers(in: newSections)

        let oldSections = sections
        sections = newSections
        updateComponentLookup(in: newSections)
        updateSectionReachedEndConfigurations(
            newSections
        )
        layoutAdapter.updateSections(newSections)

        applySnapshot(
            oldSections: oldSections,
            newSections: newSections,
            animatingDifferences: animatingDifferences,
            completion: completion
        )
    }

    /// Builder 클로저에서 만든 section model을 바로 반영합니다.
    ///
    /// - Parameters:
    ///   - animatingDifferences: Diffable 변경 애니메이션 사용 여부.
    ///   - completion: Snapshot 반영을 마친 뒤 실행할 동작.
    ///   - sectionModels: Lazy section을 만드는 builder.
    public func bind(
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil,
        @SectionModelsBuilder sectionModels: () -> SectionModels
    ) {
        bind(
            sectionModels(),
            animatingDifferences: animatingDifferences,
            completion: completion
        )
    }

    /// 현재 Compositional Layout을 다시 계산합니다.
    public func invalidateLayout() {
        collectionView?.collectionViewLayout
            .invalidateLayout()
    }
}
