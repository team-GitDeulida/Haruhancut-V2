import XCTest
import Core

final class AppUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // uitest 모드 설정
        app.launchArguments.append("-UITest")
        
        // 테스트 유저 정보
        app.launchEnvironment["TEST_USER_UID"] = "cDpXBXCFoseitthAHknJmVDPbch2"
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
        // sleep(5)
    }
    
    func test_home_upload_and_delete_flow() {
        uploadPost()
        addComment()
        deleteComment()
        deletePost()
    }
    
    // 포스트 업로드
    func uploadPost() {
        
        // 0. 홈 화면 로딩 확인 & 카메라 버튼 찾기 및 클릭
        let cameraButton = app.buttons[UITestID.Feed.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 20), "카메라 모양 버튼이 보이지 않음")
        cameraButton.tap()
        
        // 1. ActionSheet에서 "앨범에서 선택" 클릭
        let actionAlbumButton = app.buttons[UITestID.ActionSheet.album]
        XCTAssertTrue(actionAlbumButton.waitForExistence(timeout: 20), "앨범 버튼이 보이지 않음")
        actionAlbumButton.tap()
        
        // 2. 앨범 이미지가 실제로 존재할 때까지 기다림
        let imagesQuery = app.images

        let imageLoadedPredicate = NSPredicate(format: "count > 0")
        let imageExpectation = XCTNSPredicateExpectation(
            predicate: imageLoadedPredicate,
            object: imagesQuery
        )

        let waitResult = XCTWaiter().wait(for: [imageExpectation], timeout: 20)

        guard waitResult == .completed else {
            XCTFail("앨범 이미지 로딩 실패 (사진이 없거나 접근 실패)")
            return
        }

        // 3. 실제 hittable 이미지 찾기
        let firstPhoto = imagesQuery
            .allElementsBoundByIndex
            .first(where: { $0.exists && $0.isHittable })

        guard let photo = firstPhoto else {
            XCTFail("앨범에서 선택 가능한 이미지가 없음")
            return
        }

        photo.tap()
        
        // 4. 업로드 버튼 찾기 및 클릭
        let uploadButton = app.buttons[UITestID.Feed.uploadButton]
        XCTAssertTrue(uploadButton.waitForExistence(timeout: 20))
        uploadButton.tap()
        
        // 5. 홈 복귀 대기
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 20),
                      "업로드 완료 후 홈으로 복귀하지 않음")

        // 6. collectionView 등장 대기 (이제 hidden=false 상태)
        let feedCollection = app.scrollViews.firstMatch
        XCTAssertTrue(feedCollection.waitForExistence(timeout: 20),
                      "업로드 후 피드 영역 없음")
        
        // 7. 셀 최소 1개 이상 확인
        let predicate = NSPredicate(format: "count > 0")
        let expectation = XCTNSPredicateExpectation(predicate: predicate,
                                                    object: feedCollection.cells)
        
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: 20),
            .completed,
            "업로드 후 셀이 추가되지 않음"
        )
    }
    
    // 포스트 삭제
    func deletePost() {
        
        // 0. 홈 화면 로딩 확인 & 카메라 버튼 찾기 및 클릭
        let cameraButton = app.buttons[UITestID.Feed.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 20), "카메라 모양 버튼이 보이지 않음")
        
        // 1. 피드 로딩 대기
        let feedCollection = app.collectionViews[UITestID.Feed.collectionView]
            XCTAssertTrue(feedCollection.waitForExistence(timeout: 20),
                          "피드 컬렉션이 보이지 않음")
        
        // 2. 최소 1개 이상 셀 존재 확인
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
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 20),
                          "삭제 확인 알림이 나타나지 않음")
        deleteButton.tap()
        
        // 셀 감소 확인
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == %d", initialCount - 1),
            object: feedCollection.cells
        )
        
        let result = XCTWaiter().wait(for: [expectation], timeout: 20)
        XCTAssertEqual(result, .completed,
                       "삭제 후 셀이 제거되지 않음")
    }
    
    // 댓글 업로드
    func addComment() {
        // 첫번째 피드 클릭
        let feedCollection = app.collectionViews[UITestID.Feed.collectionView]
        XCTAssertTrue(feedCollection.waitForExistence(timeout: 20))
        
        let firstCell = feedCollection.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists)
        firstCell.tap()
        
        // 상세 화면 진입 대기
        let detailImage = app.images.firstMatch
        XCTAssertTrue(detailImage.waitForExistence(timeout: 20),
                      "상세 화면 진입 실패")
        
        // 댓글 버튼 탭
        let commentButton = app.buttons[UITestID.FeedDetail.commentButton]
        XCTAssertTrue(commentButton.waitForExistence(timeout: 20),
                      "댓글 버튼 없음")
        commentButton.tap()
        
        // 댓글 테이블 확인
        let commentTable = app.tables[UITestID.Comment.tableView]
        XCTAssertTrue(commentTable.waitForExistence(timeout: 20))
        
        // 댓글 초기 개수
        let initialCount = commentTable.cells.count

        // UITextView 접근
        let input = app.textViews[UITestID.Comment.inputTextView]
        XCTAssertTrue(input.waitForExistence(timeout: 20))
        
        // 댓글 텍스트필드 입력
        let testComment = "테스트 댓글입니다."
        input.tap()
        input.typeText(testComment)
        
        // 댓글 전송
        let sendButton = app.buttons[UITestID.Comment.sendButton]
        XCTAssertTrue(sendButton.exists)
        sendButton.tap()
        
        // count 증가 확인
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == %d", initialCount + 1),
            object: commentTable.cells
        )
        
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: 20),
            .completed,
            "댓글 추가 실패"
        )
    }
    
    // 댓글 삭제 및 뒤로가기
    func deleteComment() {
        
        // 댓글 테이블 확인
        let commentTable = app.tables[UITestID.Comment.tableView]
        XCTAssertTrue(commentTable.waitForExistence(timeout: 20))
        
        let initialCount = commentTable.cells.count
        XCTAssertGreaterThan(initialCount, 0, "삭제할 댓글이 없음")
        
        // 가장 마지막 셀 삭제 (방금 추가한 댓글일 확률 높음)
        let targetCell = commentTable.cells.element(boundBy: initialCount - 1)
        XCTAssertTrue(targetCell.exists)
        
        // 👉 왼쪽으로 스와이프
        targetCell.swipeLeft()
        
        // 삭제 버튼 탭
        let deleteButton = targetCell.buttons["삭제"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5),
                      "삭제 버튼이 나타나지 않음")
        deleteButton.tap()
        
        // count 감소 확인
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == %d", initialCount - 1),
            object: commentTable.cells
        )
        
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: 10),
            .completed,
            "댓글 삭제 실패"
        )
        
        // 키보드 닫기
        if app.keyboards.count > 0 {
            // app.keyboards.buttons["return"].tap()
            app.tap()   // 화면 빈 영역 터치
        }
        
        // 약한 드래그
        // commentTable.swipeDown()
        
        // 강한 드래그
        let start = commentTable.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = commentTable.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // 강한 드래그2
        let start2 = commentTable.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        let end2 = commentTable.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.2))
        start2.press(forDuration: 0.05, thenDragTo: end2)
        
        // 상세 화면 복귀 확인
        let detailImage = app.images.firstMatch
        XCTAssertTrue(detailImage.waitForExistence(timeout: 20),
                      "상세 화면 진입 실패")
        XCTAssertTrue(detailImage.waitForExistence(timeout: 10),
                      "댓글창이 내려가지 않음")
        
        // 뒤로가기
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 10),
                      "뒤로가기 버튼이 없음")
        backButton.tap()
        
        // 홈 화면 복귀 확인
        let cameraButton = app.buttons[UITestID.Feed.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 10),
                      "홈으로 복귀하지 않음")
    }
}



// 1. 피드 로딩 대기
/*
let feedCollection = app.scrollViews.firstMatch
XCTAssertTrue(feedCollection.waitForExistence(timeout: 10),
              "피드 컬렉션이 보이지 않음")
 */

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
