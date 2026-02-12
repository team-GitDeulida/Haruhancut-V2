//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//
import XCTest
@testable import Core

private struct DummySession: Codable, Equatable, CustomStringConvertible {
    var id: String
    var name: String
    
    var description: String {
        "DummySession(id: \(id), name: \(name))"
    }
}


final class UserSession2Tests: XCTestCase {
    
    private var storage: FakeUserDefaultsStorage!
    private var session: SessionContext<DummySession>!
    
    override func setUp() {
        super.setUp()
        storage = FakeUserDefaultsStorage()
        session = SessionContext<DummySession>(
                    storage: storage,
                    storageKey: "test.session"
                )
    }
    
    override func tearDown() {
        session = nil
        storage = nil
        super.tearDown()
    }
    
    // 초기 상태 테스트
    func test_init_withoutStoredSession_hasNoSession() {
        XCTAssertNil(session.session)
        XCTAssertFalse(session.hasSession)
    }

    // update(user) 테스트
    func test_update_setsSessionAndPersists() {
        let model = DummySession(id: "1", name: "apple")
        session.update(model)

        XCTAssertEqual(session.session, model)
        XCTAssertTrue(session.hasSession)
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

    // update → observe 호출됨
    func test_update_notifiesObserver() {
        let exp = expectation(description: "observer called")
        let model = DummySession(id: "1", name: "apple")

        session.observe { received in
            XCTAssertEqual(received, model)
            exp.fulfill()
        }

        session.update(model)

        wait(for: [exp], timeout: 0.1)
    }

    // KeyPath update 테스트
    func test_updateKeyPath_updatesOnlyTargetField() {
            let model = DummySession(id: "1", name: "apple")
            session.update(model)

            session.update(\.name, "banana")

            XCTAssertEqual(session.session?.name, "banana")
            XCTAssertEqual(session.session?.id, "1")
        }

    // clear 테스트
    func test_clear_removesSessionAndNotifies() {
        let exp = expectation(description: "observer called with nil")

        let model = DummySession(id: "1", name: "apple")
        session.update(model)

        session.observe { value in
            XCTAssertNil(value)
            exp.fulfill()
        }

        session.clear()

        XCTAssertNil(session.session)
        XCTAssertFalse(session.hasSession)

        wait(for: [exp], timeout: 0.1)
    }

    // storage 복원 테스트 (가장 중요)
    func test_init_restoresSessionFromStorage() {
        let stored = DummySession(id: "stored", name: "banana")

        let data = try! JSONEncoder().encode(stored)
        storage.set(data, forKey: "test.session")

        let newSession = SessionContext<DummySession>(
            storage: storage,
            storageKey: "test.session"
        )

        XCTAssertEqual(newSession.session, stored)
        XCTAssertTrue(newSession.hasSession)
    }

}


