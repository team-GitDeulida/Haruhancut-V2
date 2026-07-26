import UIKit

/// A demo implementation of a reusable diffable data source and collection-view delegate.
///
/// Keep the adapter strongly referenced for as long as its collection view is in use.
@MainActor
public final class FlowCollectionViewAdapter<SectionIdentifier: Hashable, ItemIdentifier: Hashable>:
    UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>,
    UICollectionViewDelegateFlowLayout {

    public typealias CellProvider = (
        UICollectionView,
        IndexPath,
        ItemIdentifier
    ) -> UICollectionViewCell?

    public typealias ItemHandler = (
        UICollectionView,
        IndexPath,
        ItemIdentifier
    ) -> Void

    public typealias ItemSelectionPredicate = (
        UICollectionView,
        IndexPath,
        ItemIdentifier
    ) -> Bool

    public typealias ItemSizeProvider = (
        UICollectionView,
        UICollectionViewLayout,
        IndexPath,
        ItemIdentifier
    ) -> CGSize

    public typealias SectionInsetsProvider = (
        UICollectionView,
        UICollectionViewLayout,
        Int,
        SectionIdentifier
    ) -> UIEdgeInsets

    public typealias SectionSpacingProvider = (
        UICollectionView,
        UICollectionViewLayout,
        Int,
        SectionIdentifier
    ) -> CGFloat

    public typealias SectionReferenceSizeProvider = (
        UICollectionView,
        UICollectionViewLayout,
        Int,
        SectionIdentifier
    ) -> CGSize

    public var shouldSelectItem: ItemSelectionPredicate?
    public var didSelectItem: ItemHandler?
    public var didDeselectItem: ItemHandler?

    public var willDisplayItem: (
        _ collectionView: UICollectionView,
        _ cell: UICollectionViewCell,
        _ indexPath: IndexPath,
        _ item: ItemIdentifier
    ) -> Void = { _, _, _, _ in }

    public var didEndDisplayingItem: (
        _ collectionView: UICollectionView,
        _ cell: UICollectionViewCell,
        _ indexPath: IndexPath,
        _ item: ItemIdentifier?
    ) -> Void = { _, _, _, _ in }

    public var sizeForItem: ItemSizeProvider?
    public var insetForSection: SectionInsetsProvider?
    public var minimumLineSpacing: SectionSpacingProvider?
    public var minimumInteritemSpacing: SectionSpacingProvider?
    public var referenceSizeForHeader: SectionReferenceSizeProvider?
    public var referenceSizeForFooter: SectionReferenceSizeProvider?

    public var didScroll: ((UIScrollView) -> Void)?
    public var willBeginDragging: ((UIScrollView) -> Void)?
    public var didEndDecelerating: ((UIScrollView) -> Void)?

    private var displayedItemsByCell: [ObjectIdentifier: ItemIdentifier] = [:]

    public override init(
        collectionView: UICollectionView,
        cellProvider: @escaping CellProvider
    ) {
        super.init(
            collectionView: collectionView,
            cellProvider: cellProvider
        )
        collectionView.delegate = self
    }

    /// Replaces the current snapshot with the supplied sections.
    /// Section and item identifiers must be unique within a snapshot.
    public func apply(
        sections: [CollectionViewSection<SectionIdentifier, ItemIdentifier>],
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>()
        snapshot.appendSections(sections.map(\.id))

        sections.forEach { section in
            snapshot.appendItems(section.items, toSection: section.id)
        }

        apply(
            snapshot,
            animatingDifferences: animatingDifferences,
            completion: completion
        )
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        guard
            let shouldSelectItem,
            let item = itemIdentifier(for: indexPath)
        else {
            return itemIdentifier(for: indexPath) != nil
        }

        return shouldSelectItem(collectionView, indexPath, item)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let item = itemIdentifier(for: indexPath) else { return }
        didSelectItem?(collectionView, indexPath, item)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        guard let item = itemIdentifier(for: indexPath) else { return }
        didDeselectItem?(collectionView, indexPath, item)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let item = itemIdentifier(for: indexPath) else { return }
        displayedItemsByCell[ObjectIdentifier(cell)] = item
        willDisplayItem(collectionView, cell, indexPath, item)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let item = displayedItemsByCell.removeValue(
            forKey: ObjectIdentifier(cell)
        )
        didEndDisplayingItem(
            collectionView,
            cell,
            indexPath,
            item
        )
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginDragging?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndDecelerating?(scrollView)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard
            let sizeForItem,
            let item = itemIdentifier(for: indexPath)
        else {
            return flowLayout(from: collectionViewLayout)?.itemSize ?? .zero
        }

        return sizeForItem(collectionView, collectionViewLayout, indexPath, item)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard
            let insetForSection,
            let identifier = sectionIdentifier(at: section)
        else {
            return flowLayout(from: collectionViewLayout)?.sectionInset ?? .zero
        }

        return insetForSection(collectionView, collectionViewLayout, section, identifier)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        guard
            let minimumLineSpacing,
            let identifier = sectionIdentifier(at: section)
        else {
            return flowLayout(from: collectionViewLayout)?.minimumLineSpacing ?? 0
        }

        return minimumLineSpacing(collectionView, collectionViewLayout, section, identifier)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        guard
            let minimumInteritemSpacing,
            let identifier = sectionIdentifier(at: section)
        else {
            return flowLayout(from: collectionViewLayout)?.minimumInteritemSpacing ?? 0
        }

        return minimumInteritemSpacing(collectionView, collectionViewLayout, section, identifier)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard
            let referenceSizeForHeader,
            let identifier = sectionIdentifier(at: section)
        else {
            return flowLayout(from: collectionViewLayout)?.headerReferenceSize ?? .zero
        }

        return referenceSizeForHeader(collectionView, collectionViewLayout, section, identifier)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard
            let referenceSizeForFooter,
            let identifier = sectionIdentifier(at: section)
        else {
            return flowLayout(from: collectionViewLayout)?.footerReferenceSize ?? .zero
        }

        return referenceSizeForFooter(collectionView, collectionViewLayout, section, identifier)
    }

    /// 현재 snapshot에서 지정한 위치의 Section 식별자를 안전하게 반환합니다.
    ///
    /// - Parameter index: 조회할 Section 위치.
    /// - Returns: 위치가 유효하면 Section 식별자, 아니면 `nil`.
    public func sectionIdentifier(
        at index: Int
    ) -> SectionIdentifier? {
        let identifiers = snapshot().sectionIdentifiers
        guard identifiers.indices.contains(index) else { return nil }
        return identifiers[index]
    }

    private func flowLayout(
        from collectionViewLayout: UICollectionViewLayout
    ) -> UICollectionViewFlowLayout? {
        collectionViewLayout as? UICollectionViewFlowLayout
    }
}
