import XCTest
@testable import Haruhancut
@testable import Data
import Core
import FirebaseCore

func masked(_ value: String?, prefix: Int = 5) -> String {
    guard let value else { return "nil" }
    guard value.count > prefix else { return value }
    return String(value.prefix(prefix)) + "*****"
}

enum TestBootstrap {

    static func configureFirebaseIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        print("========== 🔍 Firebase Test Environment ==========")
        
        let bundle = Bundle(for: DataIntegrationTests.self)
        
        let plistPath = bundle.path(
            forResource: "GoogleService-Info",
            ofType: "plist"
        )
        print("GoogleService-Info.plist:", plistPath ?? "❌ not found")
        
        let reversedClientId =
        bundle.object(forInfoDictionaryKey: "GOOGLE_REVERSED_CLIENT_ID") as? String
        print("GOOGLE_REVERSED_CLIENT_ID:", masked(reversedClientId))
        
        if let app = FirebaseApp.app() {
            print("FirebaseApp: ✅ configured")
            print("googleAppID:", masked(app.options.googleAppID))
            print("bundleID:", app.options.bundleID)
        } else {
            print("FirebaseApp: ❌ not configured")
        }
        
        print("===============================================")
        
    }
}

final class DataIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // 🔥 테스트 환경에서 Firebase 강제 보장
        TestBootstrap.configureFirebaseIfNeeded()
        
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

        let uid = "T9RQRMJQOeUl8pb52y1SEfpS7nj1"

        // when
        let user = try await repository.fetchUser(uid: uid).value
        
        Logger.d("user: \(String(describing: user))")

        // then
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.uid, uid)
    }
}
