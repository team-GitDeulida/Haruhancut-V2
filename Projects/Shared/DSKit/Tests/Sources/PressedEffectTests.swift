import UIKit
import XCTest
@testable import DSKit

final class PressedEffectTests:
    XCTestCase
{
    @MainActor
    func testPressedEffectAllowsScrollViewPanGesture() {
        let contentView = UIView()
        contentView.enablePressedEffect()

        guard
            let pressedGestureRecognizer =
                contentView.gestureRecognizers?
                    .compactMap({
                        $0 as?
                            UILongPressGestureRecognizer
                    })
                    .first
        else {
            return XCTFail(
                "Pressed effect recognizer 생성 실패"
            )
        }

        let scrollView = UIScrollView()
        let allowsSimultaneousRecognition =
            pressedGestureRecognizer.delegate?
                .gestureRecognizer?(
                    pressedGestureRecognizer,
                    shouldRecognizeSimultaneouslyWith:
                        scrollView
                            .panGestureRecognizer
                )
            ?? false

        XCTAssertTrue(
            allowsSimultaneousRecognition
        )
    }
}
