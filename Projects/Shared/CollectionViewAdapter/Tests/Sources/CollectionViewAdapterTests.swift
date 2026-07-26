import XCTest
import UIKit
@testable import CollectionViewAdapter

private struct TestItem: Identifiable, Equatable {
    let id: Int
    let title: String
}

private final class TestContentView:
    UIView,
    Touchable,
    ContainsButton
{
    let buttonTapEvent = ComponentEvent<Void>()
    var renderedTitle: String?
}

private struct TestComponent: Component {
    let item: TestItem

    func createContent() -> TestContentView {
        TestContentView()
    }

    func render(
        context _: ComponentContext,
        content: TestContentView
    ) {
        content.renderedTitle = item.title
    }
}

final class CollectionViewAdapterTests: XCTestCase {
    func testAnyComponentUsesItemID() {
        let component = AnyComponent(
            TestComponent(
                item: TestItem(
                    id: 7,
                    title: "계좌"
                )
            )
        )

        XCTAssertEqual(
            component.id,
            AnyHashable(7)
        )
    }

    func testSameItemIsContentEqual() {
        let oldComponent = AnyComponent(
            TestComponent(
                item: TestItem(
                    id: 7,
                    title: "계좌"
                )
            )
        )
        let newComponent = AnyComponent(
            TestComponent(
                item: TestItem(
                    id: 7,
                    title: "계좌"
                )
            )
        )

        XCTAssertTrue(
            oldComponent.isContentEqual(
                to: newComponent
            )
        )
    }

    func testChangedItemIsNotContentEqual() {
        let oldComponent = AnyComponent(
            TestComponent(
                item: TestItem(
                    id: 7,
                    title: "변경 전"
                )
            )
        )
        let newComponent = AnyComponent(
            TestComponent(
                item: TestItem(
                    id: 7,
                    title: "변경 후"
                )
            )
        )

        XCTAssertFalse(
            oldComponent.isContentEqual(
                to: newComponent
            )
        )
    }

    @MainActor
    func testEventModifierForcesRebinding() {
        let item = TestItem(
            id: 7,
            title: "계좌"
        )
        let oldComponent = AnyComponent(
            TestComponent(item: item)
                .onTouch {}
        )
        let newComponent = AnyComponent(
            TestComponent(item: item)
                .onTouch {}
        )

        XCTAssertFalse(
            oldComponent.isContentEqual(
                to: newComponent
            )
        )
    }

    @MainActor
    func testTouchableReusesEventAndGestureRecognizer() {
        let contentView = TestContentView()

        let firstEvent = contentView.touchEvent
        let secondEvent = contentView.touchEvent
        contentView.installTouchHandlingIfNeeded()
        contentView.installTouchHandlingIfNeeded()

        XCTAssertTrue(firstEvent === secondEvent)
        XCTAssertEqual(
            contentView.gestureRecognizers?.count,
            1
        )
    }

    @MainActor
    func testCellRestoresEventBindingsWhenRedisplayed() {
        var touchCount = 0
        var buttonTapCount = 0
        let component = TestComponent(
            item: TestItem(
                id: 7,
                title: "계좌"
            )
        )
        .onTouch {
            touchCount += 1
        }
        .onButtonTap {
            buttonTapCount += 1
        }
        let cell = ContainerCell<
            OnButtonTapModifier<
                OnTouchModifier<TestComponent>
            >
        >()
        cell.bindingContext = ComponentContext()
        cell.bind(component: AnyComponent(component))

        guard
            let content = cell.contentView.subviews
                .compactMap({ $0 as? TestContentView })
                .first
        else {
            return XCTFail("Component Content 생성 실패")
        }

        content.touchEvent.send(())
        content.buttonTapEvent.send(())
        XCTAssertEqual(touchCount, 1)
        XCTAssertEqual(buttonTapCount, 1)

        cell.contentDidEndDisplay()
        content.touchEvent.send(())
        content.buttonTapEvent.send(())
        XCTAssertEqual(touchCount, 1)
        XCTAssertEqual(buttonTapCount, 1)

        cell.contentWillDisplay()
        content.touchEvent.send(())
        content.buttonTapEvent.send(())
        XCTAssertEqual(touchCount, 2)
        XCTAssertEqual(buttonTapCount, 2)
    }

    @MainActor
    func testAdapterForwardsWillDisplayItem() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        let cell = UICollectionViewCell()
        let expectedIndexPath = IndexPath(
            item: 15,
            section: 0
        )
        var receivedIndexPath: IndexPath?

        adapter.willDisplayItem = {
            _, receivedCell, indexPath in
            XCTAssertTrue(receivedCell === cell)
            receivedIndexPath = indexPath
        }

        adapter.collectionView(
            collectionView,
            willDisplay: cell,
            forItemAt: expectedIndexPath
        )

        XCTAssertEqual(
            receivedIndexPath,
            expectedIndexPath
        )
    }

    @MainActor
    func testAdapterOwnsPrefetchDataSource() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )

        XCTAssertTrue(
            collectionView.prefetchDataSource === adapter
        )
    }

    @MainActor
    func testAdapterRetainsDiffableDataSource() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )

        XCTAssertTrue(
            collectionView.dataSource
                === adapter.diffableDataSource
        )
    }

    @MainActor
    func testDiffableItemIdentifierIsScopedBySection() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.bind(
            SectionModels {
                LazySection(identifier: "first") {
                    TestComponent(
                        item: TestItem(
                            id: 7,
                            title: "첫 번째 계좌"
                        )
                    )
                }
                LazySection(identifier: "second") {
                    TestComponent(
                        item: TestItem(
                            id: 7,
                            title: "두 번째 계좌"
                        )
                    )
                }
            },
            animatingDifferences: false
        )

        let itemIdentifiers =
            adapter.diffableDataSource
                .snapshot()
                .itemIdentifiers

        XCTAssertEqual(itemIdentifiers.count, 2)
        XCTAssertNotEqual(
            itemIdentifiers[0],
            itemIdentifiers[1]
        )
        XCTAssertEqual(
            itemIdentifiers.map(\.rawValue),
            [
                AnyHashable(7),
                AnyHashable(7),
            ]
        )
    }

    @MainActor
    func testAdapterAppliesAppendedItemToSnapshot() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.bind(
            SectionModels {
                LazySection(identifier: "accounts") {
                    TestComponent(
                        item: TestItem(
                            id: 7,
                            title: "여행 적금"
                        )
                    )
                }
            },
            animatingDifferences: false
        )
        let retainedItemIdentifier =
            adapter.diffableDataSource
                .snapshot()
                .itemIdentifiers
                .first

        adapter.bind(
            SectionModels {
                LazySection(identifier: "accounts") {
                    TestComponent(
                        item: TestItem(
                            id: 7,
                            title: "여행 적금"
                        )
                    )
                    TestComponent(
                        item: TestItem(
                            id: 8,
                            title: "생활비 통장"
                        )
                    )
                }
            },
            animatingDifferences: false
        )

        let snapshot =
            adapter.diffableDataSource.snapshot()
        XCTAssertEqual(
            snapshot.itemIdentifiers.first,
            retainedItemIdentifier
        )
        XCTAssertEqual(
            snapshot.itemIdentifiers.map(\.rawValue),
            [
                AnyHashable(7),
                AnyHashable(8),
            ]
        )
        XCTAssertEqual(
            adapter.componentsBySectionIdentifier[
                AnyHashable("accounts")
            ]?.count,
            2
        )
        XCTAssertNotNil(
            adapter.componentsBySectionIdentifier[
                AnyHashable("accounts")
            ]?[AnyHashable(8)]
        )
    }

    @MainActor
    func testBoundaryContentChangeDoesNotRequireSectionReload() {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        let oldModels = SectionModels {
            LazySection(identifier: "feed") {
                TestComponent(
                    item: TestItem(
                        id: 1,
                        title: "첫 번째 Item"
                    )
                )
            }
            .withHeader(
                TestComponent(
                    item: TestItem(
                        id: 100,
                        title: "1개 로드"
                    )
                ),
                height: .absolute(44)
            )
            .withFooter(
                TestComponent(
                    item: TestItem(
                        id: 200,
                        title: "대기 중"
                    )
                ),
                height: .absolute(44)
            )
        }
        let newModels = SectionModels {
            LazySection(identifier: "feed") {
                TestComponent(
                    item: TestItem(
                        id: 1,
                        title: "첫 번째 Item"
                    )
                )
                TestComponent(
                    item: TestItem(
                        id: 2,
                        title: "두 번째 Item"
                    )
                )
            }
            .withHeader(
                TestComponent(
                    item: TestItem(
                        id: 100,
                        title: "2개 로드"
                    )
                ),
                height: .absolute(44)
            )
            .withFooter(
                TestComponent(
                    item: TestItem(
                        id: 200,
                        title: "로딩 중"
                    )
                ),
                height: .absolute(44)
            )
        }
        let oldSection =
            oldModels.sections[0].resolve()
        let newSection =
            newModels.sections[0].resolve()

        XCTAssertFalse(
            adapter
                .boundaryLayoutRequiresSectionReload(
                    oldSection: oldSection,
                    newSection: newSection
                )
        )
        XCTAssertFalse(
            adapter.layoutRequiresInvalidation(
                oldSections: [oldSection],
                newSections: [newSection]
            )
        )
    }

    @MainActor
    func testLayoutConfigurationChangeRequiresInvalidation() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        let listSection =
            LazySection(identifier: "feed") {
                TestComponent(
                    item: TestItem(
                        id: 1,
                        title: "Item"
                    )
                )
            }
            .withSectionLayout(
                .verticalList(spacing: 8)
            )
            .resolve()
        let gridSection =
            LazySection(identifier: "feed") {
                TestComponent(
                    item: TestItem(
                        id: 1,
                        title: "Item"
                    )
                )
            }
            .withSectionLayout(
                .grid(
                    columns: 2,
                    interItemSpacing: 8
                )
            )
            .resolve()

        XCTAssertTrue(
            adapter.layoutRequiresInvalidation(
                oldSections: [listSection],
                newSections: [gridSection]
            )
        )
    }

    @MainActor
    func testGridPlacesEveryColumnInsideCollectionBounds() {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 400
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        let items = (0..<4).map {
            TestItem(
                id: $0,
                title: "Grid Item \($0)"
            )
        }
        adapter.bind(
            SectionModels {
                LazySection(identifier: "grid") {
                    For(of: items) {
                        TestComponent(item: $0)
                    }
                }
                .withSectionLayout(
                    .grid(
                        columns: 2,
                        estimatedRowHeight: 100,
                        interItemSpacing: 12,
                        lineSpacing: 12,
                        contentInsets:
                            NSDirectionalEdgeInsets(
                                top: 0,
                                leading: 10,
                                bottom: 0,
                                trailing: 10
                            )
                    )
                )
            },
            animatingDifferences: false
        )
        collectionView.layoutIfNeeded()

        guard
            let firstAttributes =
                collectionView
                    .collectionViewLayout
                    .layoutAttributesForItem(
                        at: IndexPath(
                            item: 0,
                            section: 0
                        )
                    ),
            let secondAttributes =
                collectionView
                    .collectionViewLayout
                    .layoutAttributesForItem(
                        at: IndexPath(
                            item: 1,
                            section: 0
                        )
                    )
        else {
            return XCTFail("Grid layout attributes 생성 실패")
        }

        XCTAssertEqual(
            firstAttributes.frame.minY,
            secondAttributes.frame.minY,
            accuracy: 0.5
        )
        XCTAssertEqual(
            firstAttributes.frame.width,
            secondAttributes.frame.width,
            accuracy: 0.5
        )
        XCTAssertGreaterThan(
            secondAttributes.frame.minX,
            firstAttributes.frame.minX
        )
        XCTAssertLessThanOrEqual(
            secondAttributes.frame.maxX,
            collectionView.bounds.maxX + 0.5
        )
    }

    @MainActor
    func testAdapterReconfiguresVisibleHeaderInPlace()
        async
    {
        let initialItems = (0..<20).map {
            TestItem(
                id: $0,
                title: "Item \($0)"
            )
        }
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 400
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.bind(
            SectionModels {
                LazySection(identifier: "feed") {
                    For(of: initialItems) {
                        TestComponent(item: $0)
                    }
                }
                .withHeader(
                    TestComponent(
                        item: TestItem(
                            id: 100,
                            title: "1개 로드"
                        )
                    ),
                    height: .absolute(44)
                )
                .withSectionLayout(
                    CollectionSectionLayout
                        .verticalList()
                        .withHeaderPinToVisibleBounds(
                            true
                        )
                )
            },
            animatingDifferences: false
        )
        collectionView.layoutIfNeeded()
        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 400
        )
        collectionView.layoutIfNeeded()

        let headerIndexPath = IndexPath(
            item: 0,
            section: 0
        )
        guard
            let firstHeader =
                collectionView.supplementaryView(
                    forElementKind:
                        UICollectionView
                            .elementKindSectionHeader,
                    at: headerIndexPath
                ),
            let firstContent =
                firstHeader.subviews
                    .compactMap({
                        $0 as? TestContentView
                    })
                    .first
        else {
            return XCTFail("첫 header 생성 실패")
        }
        XCTAssertEqual(
            firstContent.renderedTitle,
            "1개 로드"
        )
        let initialHeaderFrame = firstHeader.frame

        let updateExpectation = expectation(
            description: "Item 추가 snapshot 적용"
        )
        let updatedItems = initialItems
            + (20..<40).map {
                TestItem(
                    id: $0,
                    title: "Item \($0)"
                )
            }
        adapter.bind(
            SectionModels {
                LazySection(identifier: "feed") {
                    For(of: updatedItems) {
                        TestComponent(item: $0)
                    }
                }
                .withHeader(
                    TestComponent(
                        item: TestItem(
                            id: 100,
                            title: "2개 로드"
                        )
                    ),
                    height: .absolute(44)
                )
                .withSectionLayout(
                    CollectionSectionLayout
                        .verticalList()
                        .withHeaderPinToVisibleBounds(
                            true
                        )
                )
            },
            animatingDifferences: false,
            completion: {
                updateExpectation.fulfill()
            }
        )

        await fulfillment(
            of: [updateExpectation],
            timeout: 1
        )
        collectionView.layoutIfNeeded()

        guard
            let updatedHeader =
                collectionView.supplementaryView(
                    forElementKind:
                        UICollectionView
                            .elementKindSectionHeader,
                    at: headerIndexPath
                ),
            let updatedContent =
                updatedHeader.subviews
                    .compactMap({
                        $0 as? TestContentView
                    })
                    .first
        else {
            return XCTFail("갱신된 header 확인 실패")
        }

        XCTAssertTrue(firstHeader === updatedHeader)
        XCTAssertTrue(firstContent === updatedContent)
        XCTAssertEqual(
            updatedHeader.frame,
            initialHeaderFrame
        )
        XCTAssertEqual(
            updatedContent.renderedTitle,
            "2개 로드"
        )
    }

    @MainActor
    func testAdapterForwardsPrefetchItemsWithStableIdentifiers() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.bind(
            SectionModels {
                LazySection(identifier: "accounts") {
                    TestComponent(
                        item: TestItem(
                            id: 7,
                            title: "여행 적금"
                        )
                    )
                    TestComponent(
                        item: TestItem(
                            id: 8,
                            title: "생활비 통장"
                        )
                    )
                }
            },
            animatingDifferences: false
        )

        var receivedItems: [
            CollectionViewPrefetchItem
        ] = []
        adapter.prefetchItems = { items in
            receivedItems = items
        }

        let requestedIndexPath = IndexPath(
            item: 1,
            section: 0
        )
        adapter.collectionView(
            collectionView,
            prefetchItemsAt: [
                requestedIndexPath,
            ]
        )

        XCTAssertEqual(
            receivedItems,
            [
                CollectionViewPrefetchItem(
                    indexPath: requestedIndexPath,
                    sectionIdentifier:
                        AnyHashable("accounts"),
                    itemIdentifier:
                        AnyHashable(8)
                ),
            ]
        )
    }

    @MainActor
    func testAdapterForwardsCancelPrefetchingItems() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.bind(
            SectionModels {
                LazySection(identifier: "accounts") {
                    TestComponent(
                        item: TestItem(
                            id: 7,
                            title: "여행 적금"
                        )
                    )
                }
            },
            animatingDifferences: false
        )

        var cancelledItems: [
            CollectionViewPrefetchItem
        ] = []
        adapter.cancelPrefetchingItems = { items in
            cancelledItems = items
        }

        let requestedIndexPath = IndexPath(
            item: 0,
            section: 0
        )
        adapter.collectionView(
            collectionView,
            cancelPrefetchingForItemsAt: [
                requestedIndexPath,
            ]
        )

        XCTAssertEqual(
            cancelledItems,
            [
                CollectionViewPrefetchItem(
                    indexPath: requestedIndexPath,
                    sectionIdentifier:
                        AnyHashable("accounts"),
                    itemIdentifier:
                        AnyHashable(7)
                ),
            ]
        )
    }

    @MainActor
    func testAdapterIgnoresInvalidPrefetchIndexPath() {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )

        var callbackCount = 0
        adapter.prefetchItems = { _ in
            callbackCount += 1
        }

        adapter.collectionView(
            collectionView,
            prefetchItemsAt: [
                IndexPath(
                    item: 100,
                    section: 10
                ),
            ]
        )

        XCTAssertEqual(callbackCount, 0)
    }

    @MainActor
    func testHorizontalCarouselSectionReachesEndAtRelativeThreshold()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 400
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        let items = (0..<10).map {
            TestItem(
                id: $0,
                title: "가로 Item \($0)"
            )
        }
        let reachedEndExpectation = expectation(
            description: "가로 Section 화면 1.5배 이내 끝 접근"
        )
        var callbackCount = 0

        adapter.bind(
            SectionModels {
                LazySection(identifier: "photos") {
                    For(of: items) {
                        TestComponent(item: $0)
                    }
                }
                .withSectionLayout(
                    .horizontalCarousel(
                        itemWidth: 0.5,
                        estimatedHeight: 160,
                        spacing: 10,
                        behavior: .continuous,
                        contentInsets:
                            NSDirectionalEdgeInsets(
                                top: 0,
                                leading: 20,
                                bottom: 0,
                                trailing: 20
                            )
                    )
                )
                .onReachedEnd(
                    threshold:
                        .relativeToViewport(1.5)
                ) {
                    callbackCount += 1
                    reachedEndExpectation.fulfill()
                }
            },
            animatingDifferences: false
        )

        adapter.layoutAdapter
            .handleOrthogonalScroll(
                sectionIdentifier:
                    AnyHashable("photos"),
                contentOffset: CGPoint(
                    x: 900,
                    y: 0
                ),
                viewportWidth: 320
            )
        await Task.yield()
        await Task.yield()
        XCTAssertEqual(callbackCount, 0)

        adapter.layoutAdapter
            .handleOrthogonalScroll(
                sectionIdentifier:
                    AnyHashable("photos"),
                contentOffset: CGPoint(
                    x: 950,
                    y: 0
                ),
                viewportWidth: 320
            )

        await fulfillment(
            of: [reachedEndExpectation],
            timeout: 1
        )
        XCTAssertEqual(callbackCount, 1)
    }

    @MainActor
    func testHorizontalCarouselSectionRearmsAfterLeavingThreshold()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 400
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        let items = (0..<10).map {
            TestItem(
                id: $0,
                title: "가로 Item \($0)"
            )
        }
        let firstDeliveryExpectation = expectation(
            description: "가로 Section 첫 끝 접근"
        )
        let secondDeliveryExpectation = expectation(
            description: "가로 Section 재진입 끝 접근"
        )
        var callbackCount = 0

        adapter.bind(
            SectionModels {
                LazySection(identifier: "photos") {
                    For(of: items) {
                        TestComponent(item: $0)
                    }
                }
                .withSectionLayout(
                    .horizontalCarousel(
                        itemWidth: 0.5,
                        estimatedHeight: 160,
                        spacing: 10,
                        behavior: .continuous,
                        contentInsets:
                            NSDirectionalEdgeInsets(
                                top: 0,
                                leading: 20,
                                bottom: 0,
                                trailing: 20
                            )
                    )
                )
                .onReachedEnd(
                    threshold:
                        .relativeToViewport(1.5)
                ) {
                    callbackCount += 1
                    if callbackCount == 1 {
                        firstDeliveryExpectation
                            .fulfill()
                    } else if callbackCount == 2 {
                        secondDeliveryExpectation
                            .fulfill()
                    }
                }
            },
            animatingDifferences: false
        )

        adapter.layoutAdapter
            .handleOrthogonalScroll(
                sectionIdentifier:
                    AnyHashable("photos"),
                contentOffset: CGPoint(
                    x: 950,
                    y: 0
                ),
                viewportWidth: 320
            )
        await fulfillment(
            of: [firstDeliveryExpectation],
            timeout: 1
        )

        adapter.layoutAdapter
            .handleOrthogonalScroll(
                sectionIdentifier:
                    AnyHashable("photos"),
                contentOffset: CGPoint(
                    x: 1_000,
                    y: 0
                ),
                viewportWidth: 320
            )
        await Task.yield()
        await Task.yield()
        XCTAssertEqual(callbackCount, 1)

        adapter.layoutAdapter
            .handleOrthogonalScroll(
                sectionIdentifier:
                    AnyHashable("photos"),
                contentOffset: CGPoint(
                    x: 800,
                    y: 0
                ),
                viewportWidth: 320
            )
        adapter.layoutAdapter
            .handleOrthogonalScroll(
                sectionIdentifier:
                    AnyHashable("photos"),
                contentOffset: CGPoint(
                    x: 950,
                    y: 0
                ),
                viewportWidth: 320
            )

        await fulfillment(
            of: [secondDeliveryExpectation],
            timeout: 1
        )
        XCTAssertEqual(callbackCount, 2)
    }

    @MainActor
    func testAdapterReachesEndAtRelativeViewportThresholdBoundary()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 2_400
        )
        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 400
        )
        adapter.reachedEndThreshold =
            .relativeToViewport(1.5)

        let reachedEndExpectation = expectation(
            description: "화면 1.5배 이내 끝 접근"
        )
        adapter.reachedEnd = {
            reachedEndExpectation.fulfill()
        }

        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [reachedEndExpectation],
            timeout: 1
        )
    }

    @MainActor
    func testAdapterDoesNotReachEndBeforeRelativeThreshold()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 2_400
        )
        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 300
        )
        adapter.reachedEndThreshold =
            .relativeToViewport(1.5)

        var callbackCount = 0
        adapter.reachedEnd = {
            callbackCount += 1
        }

        adapter.scrollViewDidScroll(collectionView)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(callbackCount, 0)
    }

    @MainActor
    func testAdapterReachesEndAtAbsoluteThresholdBoundary()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 2_400
        )
        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 1_100
        )
        adapter.reachedEndThreshold = .absolute(500)

        let reachedEndExpectation = expectation(
            description: "500 point 이내 끝 접근"
        )
        adapter.reachedEnd = {
            reachedEndExpectation.fulfill()
        }

        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [reachedEndExpectation],
            timeout: 1
        )
    }

    @MainActor
    func testAdapterReachesHorizontalEndAtThresholdBoundary()
        async
    {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout: layout
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView,
            layoutAdapter:
                CollectionViewLayoutAdapter()
        )
        collectionView.contentSize = CGSize(
            width: 960,
            height: 800
        )
        collectionView.contentOffset = CGPoint(
            x: 160,
            y: 0
        )
        adapter.reachedEndThreshold =
            .relativeToViewport(1.5)

        let reachedEndExpectation = expectation(
            description: "가로 화면 1.5배 이내 끝 접근"
        )
        adapter.reachedEnd = {
            reachedEndExpectation.fulfill()
        }

        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [reachedEndExpectation],
            timeout: 1
        )
    }

    @MainActor
    func testAdapterReachedEndThresholdUsesAdjustedContentInset()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.contentInsetAdjustmentBehavior =
            .never
        collectionView.contentInset = UIEdgeInsets(
            top: 20,
            left: 0,
            bottom: 30,
            right: 0
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 2_400
        )
        adapter.reachedEndThreshold =
            .relativeToViewport(1.5)

        let reachedEndExpectation = expectation(
            description: "조정된 viewport 1.5배 이내 끝 접근"
        )
        adapter.reachedEnd = {
            reachedEndExpectation.fulfill()
        }

        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 475
        )
        adapter.scrollViewDidScroll(collectionView)
        await Task.yield()
        await Task.yield()

        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 505
        )
        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [reachedEndExpectation],
            timeout: 1
        )
    }

    @MainActor
    func testAdapterDisablesReachedEndWithoutCallback() {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 1_000
        )

        adapter.scrollViewDidScroll(collectionView)

        XCTAssertFalse(
            adapter.scrollCallbacks
                .isReachedEndDeliveryScheduled
        )
    }

    @MainActor
    func testAdapterCoalescesReachedEndDelivery()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 1_000
        )

        let reachedEndExpectation = expectation(
            description: "중복 끝 접근 요청 합치기"
        )
        reachedEndExpectation.assertForOverFulfill = true
        var callbackCount = 0
        adapter.reachedEnd = {
            callbackCount += 1
            reachedEndExpectation.fulfill()
        }

        adapter.scrollViewDidScroll(collectionView)
        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [reachedEndExpectation],
            timeout: 1
        )
        XCTAssertEqual(callbackCount, 1)
    }

    @MainActor
    func testAdapterDoesNotRepeatReachedEndWhileInsideThreshold()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 1_000
        )

        let firstDeliveryExpectation = expectation(
            description: "첫 끝 접근 callback"
        )
        let repeatedDeliveryExpectation = expectation(
            description: "영역 내부의 중복 callback 없음"
        )
        repeatedDeliveryExpectation.isInverted = true
        var callbackCount = 0
        adapter.reachedEnd = {
            callbackCount += 1
            if callbackCount == 1 {
                firstDeliveryExpectation.fulfill()
            } else {
                repeatedDeliveryExpectation.fulfill()
            }
        }

        adapter.scrollViewDidScroll(collectionView)
        await fulfillment(
            of: [firstDeliveryExpectation],
            timeout: 1
        )

        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [repeatedDeliveryExpectation],
            timeout: 0.1
        )
        XCTAssertEqual(callbackCount, 1)
    }

    @MainActor
    func testAdapterRearmsReachedEndAfterLeavingThreshold()
        async
    {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 800
            ),
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        collectionView.contentSize = CGSize(
            width: 320,
            height: 2_400
        )
        adapter.reachedEndThreshold =
            .relativeToViewport(1.5)

        let firstDeliveryExpectation = expectation(
            description: "첫 끝 접근 callback"
        )
        let secondDeliveryExpectation = expectation(
            description: "재진입 끝 접근 callback"
        )
        var callbackCount = 0
        adapter.reachedEnd = {
            callbackCount += 1
            if callbackCount == 1 {
                firstDeliveryExpectation.fulfill()
            } else if callbackCount == 2 {
                secondDeliveryExpectation.fulfill()
            }
        }

        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 400
        )
        adapter.scrollViewDidScroll(collectionView)
        await fulfillment(
            of: [firstDeliveryExpectation],
            timeout: 1
        )

        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 300
        )
        adapter.scrollViewDidScroll(collectionView)

        collectionView.contentOffset = CGPoint(
            x: 0,
            y: 400
        )
        adapter.scrollViewDidScroll(collectionView)

        await fulfillment(
            of: [secondDeliveryExpectation],
            timeout: 1
        )
        XCTAssertEqual(callbackCount, 2)
    }
}
