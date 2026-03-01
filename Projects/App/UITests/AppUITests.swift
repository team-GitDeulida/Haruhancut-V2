import XCTest
import Core

final class AppUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // 테스트 유저 정보
        app.launchEnvironment["TEST_USER_UID"] = "T9RQRMJQOeUl8pb52y1SEfpS7nj1"
        app.launch()
    }
    
    override func tearDown() {
        
        // 앱 종료
        app.terminate()
        super.tearDown()
    }
    
    func test_app_launch() {
        // 앱이 정상적으로 실행되는지 확인
        XCTAssertTrue(app.state == .runningForeground)
        sleep(5)
    }
    
    func test_home_upload_and_delete_flow() {
        uploadPost()
        deletePost()
    }
    
    // 업로드
    func uploadPost() {
        
        // 1. 초기 피드 접근 및 카운트 저장
//        let feedCollection = app.scrollViews[UITestID.Feed.collectionView]
//        XCTAssertTrue(feedCollection.waitForExistence(timeout: 10))
//        let initialCount = feedCollection.cells.count
        
        // 0. 홈 화면 로딩 확인 & 카메라 버튼 찾기 및 클릭
        let cameraButton = app.buttons[UITestID.Feed.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5), "카메라 모양 버튼이 보이지 않음")
        cameraButton.tap()
        
        // 3. ActionSheet에서 "앨범에서 선택" 클릭
        let actionAlbumButton = app.buttons[UITestID.ActionSheet.album]
        XCTAssertTrue(actionAlbumButton.waitForExistence(timeout: 3), "앨범 버튼이 보이지 않음")
        actionAlbumButton.tap()
        
        // 4. 앨범 UI 로딩 대기(시스템 UI는 약간의 여유 필요)
        sleep(2)
        
        // 5. 화면에 실제로 터치 가능한(hittable) 이미지 찾기
        guard let firstPhoto = app.images
            .allElementsBoundByIndex
            .first(where: { $0.isHittable }) else {
            XCTFail("앨범에서 선택 가능한 이미지가 없음")
            return
        }
        firstPhoto.tap()
        
        // 6. 업로드 버튼 찾기 및 클릭
        let uploadButton = app.buttons[UITestID.Feed.uploadButton]
        XCTAssertTrue(uploadButton.waitForExistence(timeout: 5))
        uploadButton.tap()
        
        // 7. 홈 복귀 대기
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 10),
                      "업로드 완료 후 홈으로 복귀하지 않음")

        // 8 collectionView 등장 대기 (이제 hidden=false 상태)
        let feedCollection = app.scrollViews.firstMatch
        XCTAssertTrue(
            feedCollection.waitForExistence(timeout: 5),
            "업로드 후 피드 영역 없음"
        )
        
        // 9️⃣ 셀 최소 1개 이상 확인
        XCTAssertGreaterThan(
            feedCollection.cells.count,
            0,
            "업로드 후 셀이 추가되지 않음"
        )
        
        // 5호 타입아웃
        sleep(5)
    }
    
    // 삭제
    func deletePost() {
        
        // 0. 홈 화면 로딩 확인 & 카메라 버튼 찾기 및 클릭
        let cameraButton = app.buttons[UITestID.Feed.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5), "카메라 모양 버튼이 보이지 않음")
        
        // 1. 피드 로딩 대기
        /*
        let feedCollection = app.scrollViews.firstMatch
        XCTAssertTrue(feedCollection.waitForExistence(timeout: 10),
                      "피드 컬렉션이 보이지 않음")
         */
        let feedCollection = app.collectionViews[UITestID.Feed.collectionView]
            XCTAssertTrue(feedCollection.waitForExistence(timeout: 10),
                          "피드 컬렉션이 보이지 않음")
        
        // 최소 1개 이상 셀 존재 확인
        XCTAssertGreaterThan(feedCollection.cells.count,
                                 0,
                                 "삭제 테스트를 위한 셀이 없음")
        
        // 초기 셀 카운트 개수
        let initialCount = feedCollection.cells.count
        
        // 첫번째 셀 롱프레스
        let firstCell = feedCollection.cells.element(boundBy: 0)
            XCTAssertTrue(firstCell.exists, "첫 번째 셀이 존재하지 않음")
        firstCell.press(forDuration: 1.0)
        
        // 삭제 버튼 확인
        let deleteButton = app.alerts.buttons["삭제"]
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 3),
                          "삭제 확인 알림이 나타나지 않음")
        deleteButton.tap()
        
        // 셀 감소 확인
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == %d", initialCount - 1),
            object: feedCollection.cells
        )
        
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed,
                       "삭제 후 셀이 제거되지 않음")
    }
}

//
//
//// 🔎 전체 접근성 트리 출력
//print("========== DEBUG START ==========")
//print(app.debugDescription)
//print("========== DEBUG END ==========")
//
//// 🔎 요소 개수 출력
//print("Images count:", app.images.count)
//print("Cells count:", app.cells.count)
//print("ScrollViews count:", app.scrollViews.count)
//print("CollectionViews count:", app.collectionViews.count)
//
//// 3️⃣ 가장 가능성 높은 접근 시도
//let firstPhoto = app.images.firstMatch
//XCTAssertTrue(firstPhoto.waitForExistence(timeout: 5))
//firstPhoto.tap()
