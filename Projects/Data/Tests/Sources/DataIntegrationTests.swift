import XCTest
import Core
@testable import Data
import FirebaseAuth
import FirebaseCore

enum TestBootstrap {

    static func configureFirebaseIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}

final class DataIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // 🔥 테스트 환경에서 Firebase 강제 보장
        // TestBootstrap.configureFirebaseIfNeeded()
        
        // 🔥 AppDelegate + Firebase 살아있는지 확인
        XCTAssertNotNil(
            FirebaseApp.app(),
            "Firebase must be configured via AppDelegate"
        )
    }
}

extension DataIntegrationTests {
    func test_fetchUser_fromFirebase() async throws {
        // given
        let repository = AuthRepositoryImpl(
            kakaoLoginManager: KakaoLoginManager(),
            appleLoginManager: AppleLoginManager(),
            firebaseAuthManager: FirebaseAuthManager(),
            firebaseStorageManager: FirebaseStorageManager()
        )

        let uid = UITestID.User.userId

        // when
        let user = try await repository.fetchUser(uid: uid).value
        
        Logger.d("user: \(String(describing: user))")

        // then
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.uid, uid)
    }
}
