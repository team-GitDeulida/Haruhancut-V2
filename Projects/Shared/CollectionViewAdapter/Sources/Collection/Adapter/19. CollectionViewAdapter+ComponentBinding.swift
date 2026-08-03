//
//  19. CollectionViewAdapter+ComponentBinding.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/26/26.
//

import UIKit

extension CollectionViewAdapter {
    /// Diffable item identifier에 해당하는 Component cell을 만듭니다.
    ///
    /// Cell에 현재 위치의 `ComponentContext`를 전달한 뒤 type-erased
    /// Component를 실제 container에 bind합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Cell을 dequeue할 collection view.
    ///   - indexPath: 생성할 Cell의 현재 위치.
    ///   - itemID: 표시할 Component를 찾는 Diffable item 식별자.
    func makeCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        itemID: AdapterItemIdentifier
    ) -> UICollectionViewCell? {
        let sectionIdentifier =
            itemID.section.rawValue
        guard
            let component =
                componentsBySectionIdentifier[
                    sectionIdentifier
                ]?[itemID.rawValue]
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
            sectionIdentifier: sectionIdentifier
        )
        (cell as? ComponentContextBindable)?
            .bindingContext = context
        (cell as? CellComponentBindable)?
            .bind(component: component)
        return cell
    }

    /// 새 Section tree를 셀 생성에 사용하는 상수 시간 조회표로 변환합니다.
    ///
    /// - Parameter sections: Component 조회표로 변환할 해석된 Section 배열.
    func updateComponentLookup(
        in sections: [ResolvedSection]
    ) {
        componentsBySectionIdentifier = Dictionary(
            uniqueKeysWithValues:
                sections.map { section in
                    (
                        section.identifier,
                        Dictionary(
                            uniqueKeysWithValues:
                                section.items.map {
                                    ($0.id, $0)
                                }
                        )
                    )
                }
        )
    }

    /// Section의 header 또는 footer Component를 표시할 view를 만듭니다.
    ///
    /// Supplementary view에도 cell과 동일한 render context와 lifecycle을
    /// 적용합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Supplementary view를 dequeue할 collection view.
    ///   - kind: 요청한 supplementary view의 UIKit element kind.
    ///   - indexPath: 생성할 supplementary view의 Section 위치.
    func makeSupplementaryView(
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

    /// Section tree에서 사용하는 cell과 supplementary container를 등록합니다.
    ///
    /// 같은 reuse key는 Adapter 수명 동안 한 번만 등록합니다.
    ///
    /// - Parameter sections: Container 등록 정보를 제공하는 해석된 Section 배열.
    func registerContainers(
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

    /// 표시 중인 Section supplementary view의 container를 유지한 채 다시 렌더링합니다.
    ///
    /// Header나 footer의 Component 타입과 layout 배치는 같고 Item 값만
    /// 달라진 경우 Section 전체 reload로 인한 깜빡임을 피합니다.
    ///
    /// - Parameters:
    ///   - kind: 다시 렌더링할 header 또는 footer의 UIKit element kind.
    ///   - sectionID: 표시 중인 supplementary view가 속한 Diffable Section ID.
    ///   - component: 기존 container에 새로 bind할 Component.
    func reconfigureVisibleSupplementaryViews(
        ofKind kind: String,
        in sectionID: AdapterSectionIdentifier,
        with component: AnyComponent
    ) {
        guard
            let collectionView,
            let sectionIndex =
                diffableDataSource.snapshot()
                    .indexOfSection(sectionID)
        else {
            return
        }

        let visibleIndexPaths =
            collectionView
                .indexPathsForVisibleSupplementaryElements(
                    ofKind: kind
                )

        for indexPath in visibleIndexPaths
        where indexPath.section == sectionIndex {
            guard
                let view =
                    collectionView.supplementaryView(
                        forElementKind: kind,
                        at: indexPath
                    )
            else {
                continue
            }

            let context = makeContext(
                collectionView: collectionView,
                indexPath: indexPath,
                sectionIdentifier:
                    sectionID.rawValue
            )
            (view as? ComponentContextBindable)?
                .bindingContext = context
            (view as? SupplementaryComponentBindable)?
                .bind(component: component)
        }
    }

    /// Component의 현재 위치와 layout 무효화 동작을 담은 context를 만듭니다.
    ///
    /// - Parameters:
    ///   - collectionView: Component를 표시하는 collection view.
    ///   - indexPath: Component가 표시될 현재 위치.
    ///   - sectionIdentifier: Component가 속한 Section의 안정적인 식별자.
    /// - Returns: Render 수명과 layout 무효화 동작을 포함한 context.
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

    /// Header 또는 footer container를 kind와 reuse key 조합별로 등록합니다.
    ///
    /// - Parameters:
    ///   - supplementary: 등록할 header 또는 footer의 Component와 배치 정보.
    ///   - collectionView: Container 클래스를 등록할 collection view.
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
}
