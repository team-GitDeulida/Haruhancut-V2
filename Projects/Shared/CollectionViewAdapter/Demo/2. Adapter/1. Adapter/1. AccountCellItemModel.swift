//
//  CollectionViewAdapter.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import UIKit

protocol CellItemModelType {
    var id: AnyHashable { get }
    var cellType: UICollectionViewCell.Type { get }
    
    func size(
        containerWidth: CGFloat
    ) -> CGSize
}

protocol CellItemModelBindable: AnyObject {
    func bind(
        itemModel: any CellItemModelType
    )
}

protocol Touchable {
    func didTouch()
}

struct AccountCellItemModel:
    CellItemModelType,
    Touchable {
    
    let account: BankAccount
    let onTouch: () -> Void
    let onTransfer: () -> Void
    
    var id: AnyHashable {
        account.id
    }
    
    var cellType: UICollectionViewCell.Type {
        AccountAdapterCell.self
    }
    
    func size(
        containerWidth: CGFloat
    ) -> CGSize {
        CGSize(
            width: containerWidth,
            height: 84
        )
    }
    
    func didTouch() {
        onTouch()
    }
}
