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
}

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

    @MainActor
    func testTouchableReusesEventAndGestureRecognizer() {
        let contentView = TestContentView()

        let firstEvent = contentView.touchEvent
        let secondEvent = contentView.touchEvent
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
}
