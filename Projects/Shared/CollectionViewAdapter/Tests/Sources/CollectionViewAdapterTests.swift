import XCTest
import UIKit
@testable import CollectionViewAdapter

private struct TestItem: Identifiable, Equatable {
    let id: Int
    let title: String
}

private final class TestContentView: UIView, Touchable {}

private struct TestComponent: Component {
    let item: TestItem

    func createContent() -> TestContentView {
        TestContentView()
    }

    func render(
        context _: ComponentContext,
        content _: TestContentView
    ) {}
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
}
