//
//  22. CollectionViewAdapter+UICollectionViewDataSourcePrefetching.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/26/26.
//

import UIKit

/// CollectionView가 곧 필요로 할 Item의 안정적인 식별 정보입니다.
///
/// IndexPath뿐 아니라 Section과 Item의 identifier를 함께 제공하므로
/// Diffable Data Source를 사용하는 화면에서도 실제 모델을 식별할 수
/// 있습니다.
public struct CollectionViewPrefetchItem: Hashable {
    /// UIKit이 전달한 현재 Item 위치입니다.
    public let indexPath: IndexPath

    /// Item이 포함된 Section의 안정적인 identifier입니다.
    public let sectionIdentifier: AnyHashable

    /// Component Item의 `Identifiable.ID`입니다.
    public let itemIdentifier: AnyHashable

    /// Prefetch 요청의 위치와 안정적인 식별 정보를 만듭니다.
    ///
    /// - Parameters:
    ///   - indexPath: UIKit이 전달한 현재 Item 위치.
    ///   - sectionIdentifier: Item이 포함된 Section의 identifier.
    ///   - itemIdentifier: Component Item의 `Identifiable.ID`.
    public init(
        indexPath: IndexPath,
        sectionIdentifier: AnyHashable,
        itemIdentifier: AnyHashable
    ) {
        self.indexPath = indexPath
        self.sectionIdentifier = sectionIdentifier
        self.itemIdentifier = itemIdentifier
    }
}

/// Prefetch 관련 공개 callback을 보관합니다.
final class CollectionViewAdapterPrefetchCallbacks {
    /// Prefetch가 필요한 Item을 전달하는 callback입니다.
    var prefetchItems: (
        _ items: [CollectionViewPrefetchItem]
    ) -> Void = { _ in }

    /// Prefetch 취소가 필요한 Item을 전달하는 callback입니다.
    var cancelPrefetchingItems: (
        _ items: [CollectionViewPrefetchItem]
    ) -> Void = { _ in }
}

extension CollectionViewAdapter:
    UICollectionViewDataSourcePrefetching
{
    /// 곧 화면에 필요할 Item을 미리 알려주는 동작입니다.
    ///
    /// 이미지 다운로드, 다음 페이지 로딩처럼 시간이 걸리는 작업을
    /// 실제 셀이 표시되기 전에 시작할 때 사용합니다.
    public var prefetchItems: (
        _ items: [CollectionViewPrefetchItem]
    ) -> Void {
        get {
            prefetchCallbacks.prefetchItems
        }
        set {
            prefetchCallbacks.prefetchItems =
                newValue
        }
    }

    /// 더 이상 미리 준비할 필요가 없는 Item을 알려주는 동작입니다.
    ///
    /// Item별 이미지 다운로드처럼 독립적으로 취소할 수 있는 작업에
    /// 사용하는 것을 권장합니다.
    public var cancelPrefetchingItems: (
        _ items: [CollectionViewPrefetchItem]
    ) -> Void {
        get {
            prefetchCallbacks
                .cancelPrefetchingItems
        }
        set {
            prefetchCallbacks
                .cancelPrefetchingItems = newValue
        }
    }

    /// UIKit의 prefetch 요청을 안정적인 Item 정보로 변환해 전달합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Prefetch 요청을 전달한 collection view.
    ///   - indexPaths: 미리 준비할 Item의 현재 위치 목록.
    public func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        let items = makePrefetchItems(
            from: indexPaths
        )
        guard !items.isEmpty else {
            return
        }
        prefetchItems(items)
    }

    /// UIKit의 prefetch 취소 요청을 안정적인 Item 정보로 변환해 전달합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Prefetch 취소 요청을 전달한 collection view.
    ///   - indexPaths: 준비 작업을 취소할 Item의 현재 위치 목록.
    public func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        let items = makePrefetchItems(
            from: indexPaths
        )
        guard !items.isEmpty else {
            return
        }
        cancelPrefetchingItems(items)
    }

    /// 현재 snapshot의 IndexPath를 Section 및 Item identifier와 결합합니다.
    ///
    /// - Parameter indexPaths: 안정적인 식별 정보로 변환할 Item 위치 목록.
    /// - Returns: 현재 snapshot에서 찾은 prefetch Item 정보 목록.
    private func makePrefetchItems(
        from indexPaths: [IndexPath]
    ) -> [CollectionViewPrefetchItem] {
        indexPaths.compactMap { indexPath in
            guard
                let itemIdentifier =
                    diffableDataSource.itemIdentifier(
                        for: indexPath
                    )
            else {
                return nil
            }

            return CollectionViewPrefetchItem(
                indexPath: indexPath,
                sectionIdentifier:
                    itemIdentifier.section.rawValue,
                itemIdentifier:
                    itemIdentifier.rawValue
            )
        }
    }
}
