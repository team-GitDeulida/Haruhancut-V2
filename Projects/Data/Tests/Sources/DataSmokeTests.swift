//
//  DataSmokeTests.swift
//  Data
//
//  Created by 김동현 on 
//

//import Testing
//@testable import Data
//
//struct RepositoryTest {
//    
//    private let authRepository: AuthRepositoryImpl
//    
//    init() {
//        let kakaoManager = KakaoLoginManager()
//        let appleManager = AppleLoginManager()
//        let firebaseAuthManager = FirebaseAuthManager()
//        let firebaseStorageManager = FirebaseStorageManager()
//        self.authRepository = AuthRepositoryImpl(kakaoLoginManager: kakaoManager,
//                                            appleLoginManager: appleManager,
//                                            firebaseAuthManager: firebaseAuthManager,
//                                            firebaseStorageManager: firebaseStorageManager)
//    }
//    
//    @Test("[Get] fetchUser")
//    func fetchUser() async throws {
//
//        // let user = try await authRepository.fetchUser(uid: "test").value
//        // #expect(user != nil)
//        #expect(true)
//    }
//}
//


//
//import XCTest
//@testable import Data
////import FirebaseCore
////import FirebaseAuth
//
//
//final class RepositoryIntegrationTests: XCTestCase {
//
//    // 🔥 Firebase는 class-level에서 단 1회만
////    override class func setUp() {
////        super.setUp()
////        
////        guard FirebaseApp.app() == nil else { return }
////        let bundle = Bundle(for: RepositoryIntegrationTests.self)
////        guard
////            let path = bundle.path(
////                forResource: "GoogleService-Info",
////                ofType: "plist"
////            ),
////            let options = FirebaseOptions(contentsOfFile: path)
////        else {
////            fatalError("❌ GoogleService-Info.plist not found in DataTests bundle")
////        }
////        
////        FirebaseApp.configure(options: options)
////    }
//
////    func test_fetchUser() async throws {
////        XCTAssertNotNil(FirebaseApp.app(), "Firebase must be configured before test")
////
////        // given
////        let kakaoManager = KakaoLoginManager()
////        let appleManager = AppleLoginManager()
////        let firebaseAuthManager = FirebaseAuthManager()
////        let firebaseStorageManager = FirebaseStorageManager()
////
////        let repository = AuthRepositoryImpl(
////            kakaoLoginManager: kakaoManager,
////            appleLoginManager: appleManager,
////            firebaseAuthManager: firebaseAuthManager,
////            firebaseStorageManager: firebaseStorageManager
////        )
////
////        let uid = "integration_test_user"
////
////        // when
////        let user = try await repository.fetchUser(uid: uid).value
////
////        // then
////        XCTAssertNotNil(user)
////    }
//    
//    
//    func test_fetchUser() async throws {
//        // XCTAssertNotNil(FirebaseApp.app(), "Firebase must be configured before test")
//
////        // given
//        let kakaoManager = KakaoLoginManager()
//        let appleManager = AppleLoginManager()
//        let firebaseAuthManager = FirebaseAuthManager()
//        let firebaseStorageManager = FirebaseStorageManager()
//
//        let repository = AuthRepositoryImpl(
//            kakaoLoginManager: kakaoManager,
//            appleLoginManager: appleManager,
//            firebaseAuthManager: firebaseAuthManager,
//            firebaseStorageManager: firebaseStorageManager
//        )
//
//        // try await Auth.auth().signInAnonymously()
//        let uid = "integration_test_user"
//
////        // when
////        let user = try await repository.fetchUser(uid: uid).value
////
////        // then
////        XCTAssertNotNil(user)
//        
//    }
//}





//    func test_fetchUser() async throws {
//
//        let kakaoManager = KakaoLoginManager()
//        let appleManager = AppleLoginManager()
//        let firebaseAuthManager = FirebaseAuthManager()
//        let firebaseStorageManager = FirebaseStorageManager()
//
//        let repository = AuthRepositoryImpl(
//            kakaoLoginManager: kakaoManager,
//            appleLoginManager: appleManager,
//            firebaseAuthManager: firebaseAuthManager,
//            firebaseStorageManager: firebaseStorageManager
//        )
//
//        let uid = "T9RQRMJQOeUl8pb52y1SEfpS7nj1"
//
//        // Single<User?> → User?
//        let user = repository.fetchUser(uid: uid)
//            .asObservable()
//            .compactMap { $0 }
//            .first() // PrimitiveSequence<SingleTrait, User??>
//
//        print("🟢 fetched user:", user as Any)
//    }



//
//import XCTest
//@testable import Data
//import FirebaseCore
//import RxSwift
//import Core
//import FirebaseDatabase
//
//
//
//class FirebaseTestBase: XCTestCase {
//
//    override class func setUp() {
//        super.setUp()
//
//        if FirebaseApp.app() == nil {
//            let bundle = Bundle(for: FirebaseTestBase.self)
//            let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist")!
//            let options = FirebaseOptions(contentsOfFile: path)!
//            FirebaseApp.configure(options: options)
//        }
//        
//        // ✅ 여기서 DB 레퍼런스 한 번 만들어보기 (여기서 터지면 100% 중복/링크 문제)
//        _ = Database.database(url: Constants.Firebase.realtimeURL).reference()
//    }
//}
//
//
//
//
//final class RepositoryIntegrationTests: FirebaseTestBase {
//    
//
//
//    
//    func test_fetchUser_rxStyle() {
//        let app = FirebaseApp.app()
//        XCTAssertNotNil(app)
//        print("🔥 Firebase name:", app?.name ?? "nil")
//        print("🔥 Firebase projectID:", app?.options.projectID ?? "nil")
//        print("🔥 Firebase databaseURL:", app?.options.databaseURL ?? "nil")
//        XCTAssertNotNil(FirebaseApp.app(), "Firebase must be configured before test")
//
//        
//        let expectation = XCTestExpectation(description: "fetch user")
//        let disposeBag = DisposeBag()
//
//        let kakaoManager = KakaoLoginManager()
//        let appleManager = AppleLoginManager()
//        let firebaseAuthManager = FirebaseAuthManager()
//        let firebaseStorageManager = FirebaseStorageManager()
//
//        let repository = AuthRepositoryImpl(
//            kakaoLoginManager: kakaoManager,
//            appleLoginManager: appleManager,
//            firebaseAuthManager: firebaseAuthManager,
//            firebaseStorageManager: firebaseStorageManager
//        )
//
//        let uid = "T9RQRMJQOeUl8pb52y1SEfpS7nj1"
//
//        repository.fetchUser(uid: uid)
//                .subscribe(
//                    onSuccess: { user in
//                        print("🟢 fetched user:", user as Any)
//                        XCTAssertNotNil(user)   // 통합 테스트 핵심
//                        expectation.fulfill()
//                    },
//                    onFailure: { error in
//                        XCTFail("❌ error: \(error)")
//                        expectation.fulfill()
//                    }
//                )
//                .disposed(by: disposeBag)
//            
//         wait(for: [expectation], timeout: 5)
//    }
//
//}
//
//
//
//
//
//import XCTest
//import FirebaseCore
//import FirebaseDatabase
//import Core
//
//enum FirebaseTestBootstrap {
//
//    static func configureIfNeeded() {
//        guard FirebaseApp.app() == nil else { return }
//
//        let bundle = Bundle.module ?? Bundle.main
//
//        guard
//            let path = bundle.path(
//                forResource: "GoogleService-Info",
//                ofType: "plist"
//            ),
//            let options = FirebaseOptions(contentsOfFile: path)
//        else {
//            fatalError("❌ GoogleService-Info.plist not found in test bundle")
//        }
//
//        FirebaseApp.configure(options: options)
//        print("✅ Firebase configured for tests")
//    }
//}
//
//class FirebaseTestBase: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//
//        // ✅ 테스트 시작 전에 강제 초기화
//        FirebaseTestBootstrap.configureIfNeeded()
//
//        // 🔒 안전 체크
//        XCTAssertNotNil(
//            FirebaseApp.app(),
//            "Firebase must be configured before any test runs"
//        )
//
//        // 🔍 DB 접근 가능해야 정상
////        _ = Database.database(
////            url: Constants.Firebase.realtimeURL
////        ).reference()
//        
//        let databaseRef = Database.database(
//            url: Constants.Firebase.realtimeURL
//        ).reference()
//    }
//}
//
//import XCTest
//@testable import Data
//import RxSwift
//
//final class RepositoryIntegrationTests: FirebaseTestBase {
//
//    private var disposeBag: DisposeBag!
//
//    override func setUp() {
//        super.setUp()
//        disposeBag = DisposeBag()
//    }
//
//    override func tearDown() {
//        disposeBag = nil
//        super.tearDown()
//    }
//    
//
//
//    func test_fetchUser_rxStyle() {
//        let expectation = XCTestExpectation(description: "fetch user")
//
//        let repository = AuthRepositoryImpl(
//            kakaoLoginManager: KakaoLoginManager(),
//            appleLoginManager: AppleLoginManager(),
//            firebaseAuthManager: FirebaseAuthManager(databaseRef: databaseRef),
//            firebaseStorageManager: FirebaseStorageManager()
//        )
//
//        let uid = "T9RQRMJQOeUl8pb52y1SEfpS7nj1"
//
//        repository.fetchUser(uid: uid)
//            .subscribe(
//                onSuccess: { user in
//                    XCTAssertNotNil(user)
//                    expectation.fulfill()
//                },
//                onFailure: { error in
//                    XCTFail("❌ error: \(error)")
//                    expectation.fulfill()
//                }
//            )
//            .disposed(by: disposeBag)
//
//        wait(for: [expectation], timeout: 5)
//    }
//}
//
//
//import XCTest
//import FirebaseCore
//import FirebaseDatabase
//import Core
//
//enum FirebaseTestBootstrap {
//
//    static func configureIfNeeded() {
//        guard FirebaseApp.app() == nil else { return }
//
//        let bundle = Bundle.module
//
//        guard
//            let path = bundle.path(
//                forResource: "GoogleService-Info",
//                ofType: "plist"
//            ),
//            let options = FirebaseOptions(contentsOfFile: path)
//        else {
//            fatalError("❌ GoogleService-Info.plist not found in test bundle")
//        }
//
//        FirebaseApp.configure(options: options)
//        print("✅ Firebase configured for tests")
//    }
//}
//
//import XCTest
//import FirebaseCore
//import FirebaseDatabase
//import Core
//
//class FirebaseTestBase: XCTestCase {
//
//    override class func setUp() {
//        super.setUp()
//        FirebaseTestBootstrap.configureIfNeeded()
//        
//        // 🔴 configure 직후 잠깐 대기
//            let exp = XCTestExpectation(description: "wait for firebase init")
//            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
//                exp.fulfill()
//            }
//
//            XCTWaiter().wait(for: [exp], timeout: 1.0)
//    }
//
//    override func setUp() {
//        super.setUp()
//        XCTAssertNotNil(FirebaseApp.app())
//    }
//
//    func makeDatabaseRef() -> DatabaseReference {
//        Database.database(url: Constants.Firebase.realtimeURL).reference()
//    }
//}
//
//
//import XCTest
//@testable import Data
//import RxSwift
//import FirebaseDatabase
//import FirebaseAuth
//
//final class RepositoryIntegrationTests: FirebaseTestBase {
//
//    private var disposeBag: DisposeBag!
//    private var databaseRef: DatabaseReference!   // ❗️ IUO OK (setUp에서 채움)
//
//    override func setUp() {
//        super.setUp()
//        print("🔥 realtimeURL =", Constants.Firebase.realtimeURL as Any)
//        disposeBag = DisposeBag()
//        databaseRef = makeDatabaseRef() // ✅ 여기서만 Firebase 접근
//    }
//
//    override func tearDown() {
//        disposeBag = nil
//        databaseRef = nil
//        super.tearDown()
//    }
//
//    func test_fetchUser_rxStyle() {
//        let expectation = XCTestExpectation(description: "fetch user")
//
//        let repository = AuthRepositoryImpl(
//            kakaoLoginManager: KakaoLoginManager(),
//            appleLoginManager: AppleLoginManager(),
//            firebaseAuthManager: FirebaseAuthManager(databaseRef: databaseRef),
//            firebaseStorageManager: FirebaseStorageManager()
//        )
//
//        let uid = "T9RQRMJQOeUl8pb52y1SEfpS7nj1"
//        
//        let test = Auth.auth().currentUser!
//        print("test: \(test)")
//
//
////        repository.fetchUser(uid: uid)
////            .subscribe(
////                onSuccess: { user in
////                    print("🟢 fetched user:", user as Any)
////                    // XCTAssertNotNil(user)
////                    // expectation.fulfill()
////                },
////                onFailure: { error in
////                    // XCTFail("❌ error: \(error)")
////                    // expectation.fulfill()
////                }
////            )
////            .disposed(by: disposeBag)
////
////        wait(for: [expectation], timeout: 5)
//    }
//}
