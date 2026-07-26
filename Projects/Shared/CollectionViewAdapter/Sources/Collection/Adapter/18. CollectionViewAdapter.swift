//
//  CollectionViewAdapter.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

private struct AdapterSectionIdentifier:
    Hashable,
    @unchecked Sendable
{
    let rawValue: AnyHashable
}

private struct AdapterItemIdentifier:
    Hashable,
    @unchecked Sendable
{
    let section: AdapterSectionIdentifier
    let rawValue: AnyHashable
}

private struct AdapterComponentSignature: Equatable {
    let component: AnyComponent

    static func == (
        lhs: AdapterComponentSignature,
        rhs: AdapterComponentSignature
    ) -> Bool {
        lhs.component.id
            == rhs.component.id
            && lhs.component.isContentEqual(
                to: rhs.component
            )
    }
}

private struct AdapterBoundarySignature: Equatable {
    enum Placement: Equatable {
        case header(
            kind: String,
            alignment: Int,
            height: CollectionLayoutDimension,
            pinToVisibleBounds: Bool,
            extendsBoundary: Bool,
            zIndex: Int
        )
        case footer(
            kind: String,
            alignment: Int,
            height: CollectionLayoutDimension,
            pinToVisibleBounds: Bool,
            extendsBoundary: Bool,
            zIndex: Int
        )
    }

    let component: AdapterComponentSignature
    let placement: Placement
}

/// Section DSL과 UIKit collection view 사이의 세부 구현을 숨기는 adapter입니다.
///
/// 외부에서는 `bind(_:)`로 section tree만 넘깁니다. 내부에서는
/// Diffable Data Source, generic container 등록, custom
/// Component cell binding, supplementary provider와
/// `CollectionViewLayoutAdapter` 동기화를 관리합니다.
@MainActor
public final class CollectionViewAdapter:
    NSObject,
    UICollectionViewDelegate
{
    /// Adapter가 관리하는 collection view입니다.
    public private(set) weak var collectionView: UICollectionView?

    /// Item이 실제 화면에 표시되기 직전에 실행할 동작입니다.
    ///
    /// 무한 스크롤처럼 표시 위치를 기준으로 동작해야 할 때 사용합니다.
    /// closure에서 화면을 캡처한다면 순환 참조를 피하도록 약하게
    /// 캡처해야 합니다.
    public var willDisplayItem: (
        _ collectionView: UICollectionView,
        _ cell: UICollectionViewCell,
        _ indexPath: IndexPath
    ) -> Void = { _, _, _ in }

    private let layoutAdapter:
        CollectionViewLayoutAdapter
    private var sections: [ResolvedSection] = []
    private var dataSource:
        UICollectionViewDiffableDataSource<
            AdapterSectionIdentifier,
            AdapterItemIdentifier
        >!
    private var registeredCellReuseKeys: Set<String> = []
    private var registeredSupplementaryReuseKeys: Set<String> =
        []

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

        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemID in
            self?.makeCell(
                collectionView: collectionView,
                indexPath: indexPath,
                itemID: itemID
            )
        }
        dataSource.supplementaryViewProvider = {
            [weak self] collectionView, kind, indexPath in
            self?.makeSupplementaryView(
                collectionView: collectionView,
                kind: kind,
                indexPath: indexPath
            )
        }
        collectionView.delegate = self
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
        layoutAdapter.updateSections(newSections)

        var snapshot = NSDiffableDataSourceSnapshot<
            AdapterSectionIdentifier,
            AdapterItemIdentifier
        >()

        for section in newSections {
            let sectionID = AdapterSectionIdentifier(
                rawValue: section.identifier
            )
            snapshot.appendSections([sectionID])
            snapshot.appendItems(
                section.items.map {
                    AdapterItemIdentifier(
                        section: sectionID,
                        rawValue: $0.id
                    )
                },
                toSection: sectionID
            )
        }

        markChangedExistingContent(
            oldSections: oldSections,
            newSections: newSections,
            snapshot: &snapshot
        )

        collectionView?.collectionViewLayout
            .invalidateLayout()
        dataSource.apply(
            snapshot,
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

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? ComponentContainerLifecycle)?
            .contentWillDisplay()
        willDisplayItem(
            collectionView,
            cell,
            indexPath
        )
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? ComponentContainerLifecycle)?
            .contentDidEndDisplay()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        (view as? ComponentContainerLifecycle)?
            .contentWillDisplay()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplayingSupplementaryView view: UICollectionReusableView,
        forElementOfKind elementKind: String,
        at indexPath: IndexPath
    ) {
        (view as? ComponentContainerLifecycle)?
            .contentDidEndDisplay()
    }

    private func makeCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        itemID: AdapterItemIdentifier
    ) -> UICollectionViewCell? {
        guard
            let section = sections.first(where: {
                $0.identifier == itemID.section.rawValue
            }),
            let component = section.items.first(where: {
                $0.id == itemID.rawValue
            })
        else {
            return nil
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: component.reuseKey,
            for: indexPath
        )

        let context = makeContext(
            collectionView: collectionView,
            indexPath: indexPath,
            sectionIdentifier: section.identifier
        )
        (cell as? ComponentContextBindable)?
            .bindingContext = context
        (cell as? CellComponentBindable)?
            .bind(component: component)
        return cell
    }

    private func makeSupplementaryView(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath
    ) -> UICollectionReusableView? {
        guard sections.indices.contains(indexPath.section)
        else {
            return nil
        }

        let section = sections[indexPath.section]
        let component: AnyComponent

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = section.header else {
                return nil
            }
            component = header.component
        case UICollectionView.elementKindSectionFooter:
            guard let footer = section.footer else {
                return nil
            }
            component = footer.component
        default:
            return nil
        }

        let view =
            collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: component.reuseKey,
                for: indexPath
            )
        let context = makeContext(
            collectionView: collectionView,
            indexPath: indexPath,
            sectionIdentifier: section.identifier
        )
        (view as? ComponentContextBindable)?
            .bindingContext = context
        (view as? SupplementaryComponentBindable)?
            .bind(component: component)
        return view
    }

    private func makeContext(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        sectionIdentifier: AnyHashable
    ) -> ComponentContext {
        ComponentContext(
            collectionView: collectionView,
            indexPath: indexPath,
            sectionIdentifier: sectionIdentifier
        ) { [weak collectionView] in
            collectionView?.collectionViewLayout
                .invalidateLayout()
        }
    }

    private func validate(_ sections: [ResolvedSection]) {
        var sectionIDs: Set<AnyHashable> = []

        for section in sections {
            precondition(
                sectionIDs.insert(section.identifier).inserted,
                "중복 section identifier: \(section.identifier)"
            )

            var itemIDs: Set<AnyHashable> = []
            for item in section.items {
                precondition(
                    itemIDs.insert(item.id).inserted,
                    "section \(section.identifier)의 중복 item ID: \(item.id)"
                )
            }
        }
    }

    private func registerContainers(
        in sections: [ResolvedSection]
    ) {
        guard let collectionView else { return }

        for section in sections {
            for component in section.items
            where registeredCellReuseKeys
                .insert(component.reuseKey).inserted {
                collectionView.register(
                    component.cellContainerType,
                    forCellWithReuseIdentifier:
                        component.reuseKey
                )
            }

            if let header = section.header {
                registerSupplementary(
                    header,
                    collectionView: collectionView
                )
            }

            if let footer = section.footer {
                registerSupplementary(
                    footer,
                    collectionView: collectionView
                )
            }
        }
    }

    private func registerSupplementary(
        _ supplementary: SupplementaryView,
        collectionView: UICollectionView
    ) {
        let component = supplementary.component
        let kind = supplementary.kind
        let registrationKey = "\(kind)|\(component.reuseKey)"
        guard
            registeredSupplementaryReuseKeys
                .insert(registrationKey).inserted
        else {
            return
        }

        collectionView.register(
            supplementary.containerType,
            forSupplementaryViewOfKind: kind,
            withReuseIdentifier: component.reuseKey
        )
    }

    private func markChangedExistingContent(
        oldSections: [ResolvedSection],
        newSections: [ResolvedSection],
        snapshot: inout NSDiffableDataSourceSnapshot<
            AdapterSectionIdentifier,
            AdapterItemIdentifier
        >
    ) {
        let oldByID = Dictionary(
            uniqueKeysWithValues: oldSections.map {
                ($0.identifier, $0)
            }
        )
        let oldSnapshotSectionIDs = Set(
            dataSource.snapshot().sectionIdentifiers
        )

        for newSection in newSections {
            guard
                let oldSection =
                    oldByID[newSection.identifier]
            else {
                continue
            }

            let sectionID = AdapterSectionIdentifier(
                rawValue: newSection.identifier
            )
            guard oldSnapshotSectionIDs.contains(sectionID)
            else {
                continue
            }

            if boundarySignature(of: oldSection)
                != boundarySignature(of: newSection) {
                snapshot.reloadSections([sectionID])
                continue
            }

            let oldItems = Dictionary(
                uniqueKeysWithValues:
                    oldSection.items.map {
                        ($0.id, $0)
                    }
            )
            var itemsToReload: [AdapterItemIdentifier] = []
            var itemsToReconfigure:
                [AdapterItemIdentifier] = []

            for newItem in newSection.items {
                guard
                    let oldItem = oldItems[newItem.id]
                else {
                    continue
                }

                let itemID = AdapterItemIdentifier(
                    section: sectionID,
                    rawValue: newItem.id
                )
                if oldItem.reuseKey != newItem.reuseKey {
                    itemsToReload.append(itemID)
                } else if !oldItem.isContentEqual(
                    to: newItem
                ) {
                    itemsToReconfigure.append(itemID)
                }
            }

            if !itemsToReload.isEmpty {
                snapshot.reloadItems(itemsToReload)
            }
            if !itemsToReconfigure.isEmpty {
                snapshot.reconfigureItems(
                    itemsToReconfigure
                )
            }
        }
    }

    private func boundarySignature(
        of section: ResolvedSection
    ) -> [AdapterBoundarySignature] {
        var signatures: [AdapterBoundarySignature] = []

        if let header = section.header {
            signatures.append(
                AdapterBoundarySignature(
                    component:
                        AdapterComponentSignature(
                            component: header.component
                        ),
                    placement: .header(
                        kind: header.kind,
                        alignment:
                            header.alignment.rawValue,
                        height: header.height,
                        pinToVisibleBounds:
                            section.layout
                                .pinsHeaderToVisibleBounds,
                        extendsBoundary:
                            header.extendsBoundary,
                        zIndex: header.zIndex
                    )
                )
            )
        }

        if let footer = section.footer {
            signatures.append(
                AdapterBoundarySignature(
                    component:
                        AdapterComponentSignature(
                            component: footer.component
                        ),
                    placement: .footer(
                        kind: footer.kind,
                        alignment:
                            footer.alignment.rawValue,
                        height: footer.height,
                        pinToVisibleBounds:
                            section.layout
                                .pinsFooterToVisibleBounds,
                        extendsBoundary:
                            footer.extendsBoundary,
                        zIndex: footer.zIndex
                    )
                )
            )
        }

        return signatures
    }
}
