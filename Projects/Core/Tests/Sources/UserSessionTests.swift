//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//
import XCTest
@testable import Core

final class UserSession2Tests: XCTestCase {
    
    private var storage: FakeUserDefaultsStorage!
    private var session: UserSession!
    
    override func setUp() {
        super.setUp()
        storage = FakeUserDefaultsStorage()
        session = UserSession(storage: storage)
    }
    
    override func tearDown() {
        session = nil
        storage = nil
        super.tearDown()
    }
    
    // 초기 상태 테스트
    func test_init_withoutStoredSession_hasNoSession() {
        XCTAssertNil(session.sessionUser)
        XCTAssertFalse(session.isLoggedIn)
        XCTAssertFalse(session.hasGroup)
    }

    // update(user) 테스트
    func test_updateUser_setsSessionAndMarksLoggedIn() {
        let user = SessionUser(userId: "user-1", groupId: nil)

        session.update(user)

        XCTAssertEqual(session.sessionUser, user)
        XCTAssertTrue(session.isLoggedIn)
        XCTAssertFalse(session.hasGroup)
    }
    
    // bind는 즉시 1회 호출된다
    func test_bind_callsHandlerImmediatelyWithCurrentState() {
        let exp = expectation(description: "bind called immediately")

        session.bind { user in
            XCTAssertNil(user)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
    }
    
    // observe는 초기 호출
    func test_observe_doesNotCallImmediately() {
        var callCount = 0

        session.observe { _ in
            callCount += 1
        }

        XCTAssertEqual(callCount, 0)
    }

    // update(user) → observe 호출됨
    func test_updateUser_notifiesObserver() {
        let exp = expectation(description: "observer called")
        let user = SessionUser(userId: "user-1", groupId: nil)

        session.observe { received in
            XCTAssertEqual(received, user)
            exp.fulfill()
        }

        session.update(user)

        wait(for: [exp], timeout: 0.1)
    }

    // KeyPath update 테스트
    func test_updateKeyPath_updatesOnlyTargetField() {
        let user = SessionUser(userId: "user-1", groupId: nil)
        session.update(user)

        session.update(\.groupId, "group-1")

        XCTAssertEqual(session.sessionUser?.groupId, "group-1")
        XCTAssertEqual(session.sessionUser?.userId, "user-1")
    }

    // clear 테스트
    func test_clear_removesSessionAndNotifies() {
        let exp = expectation(description: "observer called with nil")

        session.update(SessionUser(userId: "user-1", groupId: nil))

        session.observe { user in
            XCTAssertNil(user)
            exp.fulfill()
        }

        session.clear()

        XCTAssertNil(session.sessionUser)
        XCTAssertFalse(session.isLoggedIn)

        wait(for: [exp], timeout: 0.1)
    }

    // storage 복원 테스트 (가장 중요)
    func test_init_restoresSessionFromStorage() {
        let storedUser = SessionUser(userId: "stored", groupId: "group")

        let data = try! JSONEncoder().encode(storedUser)
        storage.set(data, forKey: "session.user")

        let newSession = UserSession(storage: storage)

        XCTAssertEqual(newSession.sessionUser, storedUser)
        XCTAssertTrue(newSession.isLoggedIn)
        XCTAssertTrue(newSession.hasGroup)
    }

}


