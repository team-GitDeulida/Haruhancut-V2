//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//
import Testing
@testable import Core
import Foundation

@Suite("UserSession Tests")
struct UserSessionTests {

    private let storage: FakeUserDefaultsStorage
    private let session: UserSession

    init() {
        self.storage = FakeUserDefaultsStorage()
        self.session = UserSession(storage: storage)
    }

    // 초기 상태 테스트
    @Test("Init without stored session → no session")
    func initWithoutStoredSession() {
        #expect(session.sessionUser == nil)
        #expect(session.isLoggedIn == false)
        #expect(session.hasGroup == false)
    }

    // update(user) 테스트
    @Test("Update user sets session and marks logged in")
    func updateUser() {
        let user = SessionUser(userId: "user-1", groupId: nil)

        session.update(user)

        #expect(session.sessionUser == user)
        #expect(session.isLoggedIn == true)
        #expect(session.hasGroup == false)
    }

    // bind는 즉시 1회 호출된다
    @Test("Bind calls handler immediately with current state")
    func bindCallsImmediately() async {
        await confirmation { confirm in
            session.bind { user in
                #expect(user == nil)
                confirm()
            }
        }
    }

    // observe는 초기 호출 ❌
    @Test("Observe does not call immediately")
    func observeDoesNotCallImmediately() {
        var callCount = 0

        session.observe { _ in
            callCount += 1
        }

        #expect(callCount == 0)
    }

    // update(user) → observe 호출됨
    @Test("Update user notifies observer")
    func updateNotifiesObserver() async {
        let user = SessionUser(userId: "user-1", groupId: nil)

        await confirmation { confirm in
            session.observe { received in
                #expect(received == user)
                confirm()
            }

            session.update(user)
        }
    }

    // KeyPath update 테스트
    @Test("Update keyPath updates only target field")
    func updateKeyPath() {
        let user = SessionUser(userId: "user-1", groupId: nil)
        session.update(user)

        session.update(\.groupId, "group-1")

        #expect(session.sessionUser?.groupId == "group-1")
        #expect(session.sessionUser?.userId == "user-1")
    }

    // clear 테스트
    @Test("Clear removes session and notifies observer")
    func clearRemovesSession() async {
        session.update(SessionUser(userId: "user-1", groupId: nil))

        await confirmation { confirm in
            session.observe { user in
                #expect(user == nil)
                confirm()
            }

            session.clear()
        }

        #expect(session.sessionUser == nil)
        #expect(session.isLoggedIn == false)
    }

    // storage 복원 테스트 (가장 중요)
    @Test("Init restores session from storage")
    func restoreFromStorage() {
        let storedUser = SessionUser(userId: "stored", groupId: "group")
        let data = try! JSONEncoder().encode(storedUser)

        storage.set(data, forKey: "session.user")

        let newSession = UserSession(storage: storage)

        #expect(newSession.sessionUser == storedUser)
        #expect(newSession.isLoggedIn == true)
        #expect(newSession.hasGroup == true)
    }
}
