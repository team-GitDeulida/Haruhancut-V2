import UIKit
import XCTest
@testable import CollectionViewAdapter

@MainActor
final class CollectionViewAdapterTests: XCTestCase {
    private enum Section: Hashable {
        case main
        case archive
    }

    func testInitializationConnectsDataSourceAndDelegate() {
        let collectionView = makeCollectionView()
        let adapter = makeAdapter(collectionView: collectionView)

        XCTAssertTrue(collectionView.dataSource === adapter)
        XCTAssertTrue(collectionView.delegate === adapter)
    }

    func testApplyingSectionsBuildsSnapshotInOrder() {
        let collectionView = makeCollectionView()
        let adapter = makeAdapter(collectionView: collectionView)

        adapter.apply(
            sections: [
                CollectionViewSection(id: .main, items: [1, 2]),
                CollectionViewSection(id: .archive, items: [3])
            ],
            animatingDifferences: false
        )

        XCTAssertEqual(adapter.snapshot().sectionIdentifiers, [.main, .archive])
        XCTAssertEqual(adapter.snapshot().itemIdentifiers, [1, 2, 3])
        XCTAssertEqual(adapter.itemIdentifier(for: IndexPath(item: 1, section: 0)), 2)
    }

    func testSelectionForwardsResolvedItemToHandler() {
        let collectionView = makeCollectionView()
        let adapter = makeAdapter(collectionView: collectionView)
        var selectedItem: Int?

        adapter.apply(
            sections: [CollectionViewSection(id: .main, items: [10])],
            animatingDifferences: false
        )
        adapter.didSelectItem = { _, _, item in
            selectedItem = item
        }

        adapter.collectionView(
            collectionView,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertEqual(selectedItem, 10)
    }

    func testFlowLayoutUsesConfiguredSizeProvider() {
        let collectionView = makeCollectionView()
        let adapter = makeAdapter(collectionView: collectionView)
        let expectedSize = CGSize(width: 120, height: 80)

        adapter.apply(
            sections: [CollectionViewSection(id: .main, items: [10])],
            animatingDifferences: false
        )
        adapter.sizeForItem = { _, _, _, _ in expectedSize }

        let size = adapter.collectionView(
            collectionView,
            layout: collectionView.collectionViewLayout,
            sizeForItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertEqual(size, expectedSize)
    }

    func testEndDisplayingKeepsItemFromBeforeSnapshotUpdate() {
        let collectionView = makeCollectionView()
        let adapter = makeAdapter(collectionView: collectionView)
        let cell = UICollectionViewCell()
        var endedItem: Int?

        adapter.apply(
            sections: [CollectionViewSection(id: .main, items: [10])],
            animatingDifferences: false
        )
        adapter.collectionView(
            collectionView,
            willDisplay: cell,
            forItemAt: IndexPath(item: 0, section: 0)
        )
        adapter.apply(
            sections: [CollectionViewSection(id: .main, items: [20])],
            animatingDifferences: false
        )
        adapter.didEndDisplayingItem = { _, _, _, item in
            endedItem = item
        }

        adapter.collectionView(
            collectionView,
            didEndDisplaying: cell,
            forItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertEqual(endedItem, 10)
    }

    private func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 640),
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: "Cell"
        )
        return collectionView
    }

    private func makeAdapter(
        collectionView: UICollectionView
    ) -> CollectionViewAdapter<Section, Int> {
        CollectionViewAdapter(collectionView: collectionView) { collectionView, indexPath, _ in
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "Cell",
                for: indexPath
            )
        }
    }
}
