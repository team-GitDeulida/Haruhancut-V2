//
//  CollectionViewAdapter+ComponentBinding.swift
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
    func makeCell(
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

    /// Section의 header 또는 footer Component를 표시할 view를 만듭니다.
    ///
    /// Supplementary view에도 cell과 동일한 render context와 lifecycle을
    /// 적용합니다.
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

    /// Component의 현재 위치와 layout 무효화 동작을 담은 context를 만듭니다.
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
