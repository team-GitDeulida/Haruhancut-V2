//
//  SupplementaryView.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Section header 또는 footer에 배치할 Component와 layout 정보입니다.
///
/// `SupplementaryView`는 새로운 Component 종류가 아닙니다. 일반
/// `Component`를 UIKit supplementary 위치에 연결하는 Section 소유의
/// 배치 값입니다. 사용자는 직접 만들기보다 `withHeader(_:)`와
/// `withFooter(_:)`를 사용합니다.
@MainActor
public struct SupplementaryView {
    let component: AnyComponent
    let containerType: AnyClass
    let kind: String
    let alignment: NSRectAlignment
    let height: CollectionLayoutDimension
    let extendsBoundary: Bool
    let zIndex: Int

    init<C: Component>(
        component: C,
        kind: String,
        alignment: NSRectAlignment,
        height: CollectionLayoutDimension? = nil,
        extendsBoundary: Bool = true,
        zIndex: Int = 0
    ) {
        let erased = AnyComponent(component)
        self.component = erased
        containerType = ContainerSupplementaryView<C>.self
        self.kind = kind
        self.alignment = alignment
        self.height =
            height ?? .estimated(erased.estimatedHeight)
        self.extendsBoundary = extendsBoundary
        self.zIndex = zIndex
    }

    func makeLayoutItem() ->
        NSCollectionLayoutBoundarySupplementaryItem
    {
        let item =
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: height.layoutDimension
                ),
                elementKind: kind,
                alignment: alignment
            )
        item.extendsBoundary = extendsBoundary
        item.zIndex = zIndex
        return item
    }
}
