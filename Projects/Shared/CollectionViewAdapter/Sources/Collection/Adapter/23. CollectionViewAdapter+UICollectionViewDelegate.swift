//
//  23. CollectionViewAdapter+UICollectionViewDelegate.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/26/26.
//

import UIKit

/// `UICollectionViewDelegate` 관련 공개 callback을 보관합니다.
final class CollectionViewAdapterDelegateCallbacks {
    /// 화면에 표시되기 시작한 Item을 전달하는 callback입니다.
    var willDisplayItem: (
        _ collectionView: UICollectionView,
        _ cell: UICollectionViewCell,
        _ indexPath: IndexPath
    ) -> Void = { _, _, _ in }
}

extension CollectionViewAdapter: UICollectionViewDelegate {
    /// Item이 실제 화면에 표시되기 직전에 실행할 동작입니다.
    ///
    /// 무한 스크롤처럼 표시 위치를 기준으로 동작해야 할 때 사용합니다.
    /// closure에서 화면을 캡처한다면 순환 참조를 피하도록 약하게
    /// 캡처해야 합니다.
    public var willDisplayItem: (
        _ collectionView: UICollectionView,
        _ cell: UICollectionViewCell,
        _ indexPath: IndexPath
    ) -> Void {
        get {
            delegateCallbacks.willDisplayItem
        }
        set {
            delegateCallbacks.willDisplayItem =
                newValue
        }
    }

    /// Cell의 render 수명을 다시 활성화하고 공개 callback을 전달합니다.
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

    /// 화면에서 사라진 Cell의 render 단위 작업을 정리합니다.
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? ComponentContainerLifecycle)?
            .contentDidEndDisplay()
    }

    /// 화면에 표시되는 supplementary view의 render 수명을 활성화합니다.
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        (view as? ComponentContainerLifecycle)?
            .contentWillDisplay()
    }

    /// 화면에서 사라진 supplementary view의 render 단위 작업을 정리합니다.
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplayingSupplementaryView view: UICollectionReusableView,
        forElementOfKind elementKind: String,
        at indexPath: IndexPath
    ) {
        (view as? ComponentContainerLifecycle)?
            .contentDidEndDisplay()
    }
}
