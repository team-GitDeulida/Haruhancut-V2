@testable import HomeFeatureV2
import XCTest

final class FeedViewLayerTests: XCTestCase {
    func testFeedGridIsLayeredAboveUploadControls() {
        let view =
            FeedView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: 390,
                    height: 844
                )
            )

        let cameraButtonIndex =
            tryUnwrap(
                view.subviews.firstIndex(
                    of: view.cameraBtn
                )
            )
        let bubbleViewIndex =
            tryUnwrap(
                view.subviews.firstIndex(
                    of: view.bubbleView
                )
            )
        let collectionViewIndex =
            tryUnwrap(
                view.subviews.firstIndex(
                    of: view.collectionView
                )
            )

        XCTAssertGreaterThan(
            collectionViewIndex,
            cameraButtonIndex
        )
        XCTAssertGreaterThan(
            collectionViewIndex,
            bubbleViewIndex
        )
        XCTAssertEqual(
            view.collectionView.backgroundColor,
            .clear
        )
    }

    func testCameraButtonReceivesTouchAboveFeedGrid() {
        let view =
            FeedView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: 390,
                    height: 844
                )
            )
        view.layoutIfNeeded()

        let hitView =
            view.hitTest(
                view.cameraBtn.center,
                with: nil
            )

        XCTAssertTrue(
            hitView === view.cameraBtn ||
                hitView?.isDescendant(
                    of: view.cameraBtn
                ) == true
        )
    }

    private func tryUnwrap(
        _ value: Int?
    ) -> Int {
        guard let value else {
            XCTFail("필수 뷰가 계층에 없습니다.")
            return -1
        }
        return value
    }
}
