//
//  CollectionViewAdapter+DiffableDataSource.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/26/26.
//

import UIKit

/// Diffable snapshot에서 Section을 식별하는 내부 값입니다.
struct AdapterSectionIdentifier:
    Hashable,
    @unchecked Sendable
{
    /// 사용자가 Section에 지정한 원본 identifier입니다.
    let rawValue: AnyHashable
}

/// Diffable snapshot에서 Item을 식별하는 내부 값입니다.
///
/// 서로 다른 Section에서 동일한 Item ID를 사용할 수 있도록 Section
/// identifier를 함께 보관합니다.
struct AdapterItemIdentifier:
    Hashable,
    @unchecked Sendable
{
    /// Item이 속한 Section identifier입니다.
    let section: AdapterSectionIdentifier

    /// Component Item의 원본 `Identifiable.ID`입니다.
    let rawValue: AnyHashable
}

/// Adapter가 소유하는 Diffable Data Source 타입입니다.
typealias AdapterDiffableDataSource =
    UICollectionViewDiffableDataSource<
        AdapterSectionIdentifier,
        AdapterItemIdentifier
    >

/// Adapter가 생성하고 적용하는 Diffable snapshot 타입입니다.
private typealias AdapterSnapshot =
    NSDiffableDataSourceSnapshot<
        AdapterSectionIdentifier,
        AdapterItemIdentifier
    >

/// Item의 화면 표시 상태가 바뀌었는지 비교하기 위한 값입니다.
private struct AdapterComponentSignature: Equatable {
    /// 비교할 type-erased Component입니다.
    let component: AnyComponent

    /// Component의 ID, Item 상태와 modifier 연결 상태를 비교합니다.
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

/// Section boundary supplementary의 표시와 배치 상태를 비교하는 값입니다.
private struct AdapterBoundarySignature: Equatable {
    /// Boundary view의 종류와 layout 설정입니다.
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

    /// Header 또는 footer에 표시할 Component 상태입니다.
    let component: AdapterComponentSignature

    /// Header 또는 footer의 layout 배치 상태입니다.
    let placement: Placement
}

extension CollectionViewAdapter {
    /// Cell과 supplementary provider가 연결된 Diffable Data Source를 만듭니다.
    func makeDiffableDataSource()
        -> AdapterDiffableDataSource
    {
        guard let collectionView else {
            preconditionFailure(
                "CollectionViewAdapter의 collectionView가 없습니다."
            )
        }

        let dataSource = AdapterDiffableDataSource(
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
        return dataSource
    }

    /// 새 Section tree로 snapshot을 만들고 변경된 기존 Content를 갱신합니다.
    func applySnapshot(
        oldSections: [ResolvedSection],
        newSections: [ResolvedSection],
        animatingDifferences: Bool,
        completion: (() -> Void)?
    ) {
        var snapshot = makeSnapshot(
            from: newSections
        )
        markChangedExistingContent(
            oldSections: oldSections,
            newSections: newSections,
            snapshot: &snapshot
        )

        collectionView?.collectionViewLayout
            .invalidateLayout()
        diffableDataSource.apply(
            snapshot,
            animatingDifferences: animatingDifferences,
            completion: completion
        )
    }

    /// Diffable Data Source에서 충돌하는 Section과 Item ID가 없는지 검사합니다.
    func validate(
        _ sections: [ResolvedSection]
    ) {
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

    /// 해석된 Section tree를 Diffable snapshot으로 변환합니다.
    private func makeSnapshot(
        from sections: [ResolvedSection]
    ) -> AdapterSnapshot {
        var snapshot = AdapterSnapshot()

        for section in sections {
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

        return snapshot
    }

    /// 같은 ID로 유지되면서 표시 상태가 바뀐 기존 Item과 Section을 표시합니다.
    ///
    /// Container 타입이 바뀐 Item은 reload하고, 같은 타입의 Content만 바뀐
    /// Item은 reconfigure합니다. Boundary 상태가 바뀌면 Section을 reload합니다.
    private func markChangedExistingContent(
        oldSections: [ResolvedSection],
        newSections: [ResolvedSection],
        snapshot: inout AdapterSnapshot
    ) {
        let oldByID = Dictionary(
            uniqueKeysWithValues: oldSections.map {
                ($0.identifier, $0)
            }
        )
        let oldSnapshotSectionIDs = Set(
            diffableDataSource.snapshot().sectionIdentifiers
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

    /// Section header와 footer의 Content 및 layout 상태를 비교 가능한 값으로 만듭니다.
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
