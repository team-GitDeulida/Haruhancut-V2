import XCTest

final class AppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }

    func test_app_launch() {
        // 앱이 정상적으로 실행되는지 확인
        XCTAssertTrue(app.state == .runningForeground)
    }
}
