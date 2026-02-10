////
////  UserSession.swift
////  App
////
////  Created by 김동현 on 1/25/26.
////
//
//import Foundation
//
//// MARK: - Session Model
//// 로그인된 사용자를 표현하는 세션 모델
//// - Auth Context에서 사용되며
//// - storage에 저장/복원될 수 있도록 Codable 채택
//public struct SessionUser: Codable, Equatable {
//    public var userId: String
//    public var groupId: String?
//    
//    public init(userId: String, groupId: String?) {
//        self.userId = userId
//        self.groupId = groupId
//    }
//    
//    public var description: String {
//            """
//            SessionUser(
//              userId: \(userId),
//              groupId: \(groupId ?? "nil")
//            )
//            """
//    }
//}
//
//// MARK: - UserSession Interface
//// UserSession이 제공해야 하는 최소한의 기능 정의
//// - 세션 조회
//// - 로그인 여부 판단
//// - 세션 변경 감지
//// - 세션 갱신 / 초기화
//public protocol UserSessionType {
//    
//    // 세션 변경 시 호출되는 콜백 타입
//    // - 로그인: SessionUser
//    // - 로그아웃: nil
//    typealias SessionChangeHandler = (SessionUser?) -> Void
//    
//    // 현재 세션 유저 (읽기 전용)
//    var sessionUser: SessionUser? { get }
//    
//    // 로그인 여부 판단용 플래그
//    var isLoggedIn: Bool { get }
//    
//    // 그룹 여부
//    var hasGroup: Bool { get }
//    
//    // 세션 상태를 구독
//    // - bind 즉시 현재 상태를 한 번 전달
//    func bind(_ handler: @escaping SessionChangeHandler)
//    
//    /// 상태 변경만 감지 (초기 호출 ❌)
//    func observe(_ handler: @escaping SessionChangeHandler)
//    
//    // 로그인/세션 갱신
//    func update(_ user: SessionUser)
//    
//    // 로그아웃/세션 초기화
//    func clear()
//    
//    /// SessionUser의 특정 속성만 업데이트한다.
//    func update<Value>(_ keyPath: WritableKeyPath<SessionUser, Value>,
//                       _ value: Value
//    )
//}
//
//// MARK: - UserSession Implementation
//// 앱 전역에서 사용되는 세션 컨텍스트 객체
//// - 메모리 캐시 + 로컬 storage를 함께 관리
//// - single source of truth는 cachedUser
//public final class UserSession: UserSessionType {
//
//    // 로컬 저장소 (UserDefaults, Keychain 등 추상화)
//    private let storage: UserDefaultsStorageManager
//    
//    // 세션 변경을 감지하는 외부 콜백
//    // 현재 구조에서는 하나의 observer만 유지
//    private var onSessionChanged: (SessionChangeHandler)?
//    private var cachedUser: SessionUser? // 캐시
//    
//    private enum Key {
//        static let user = "session.user"
//    }
//    
//    public init(storage: UserDefaultsStorageManager) {
//        self.storage = storage
//        self.cachedUser = self.loadFromStorage()
//        Logger.d("\(String(describing: self.sessionUser))")
//    }
//}
//
//// MARK: - Private
//private extension UserSession {
//    
//    // storage에서 SessionUser를 로드
//    // - 데이터가 없거나 디코딩 실패 시 nil 반환
//    // - init 시점에 한 번만 호출됨
//    func loadFromStorage() -> SessionUser? {
//        guard let data: Data = storage.get(forKey: Key.user) else { return nil }
//        return try? JSONDecoder().decode(SessionUser.self, from: data)
//    }
//    
//    // SessionUser를 storage에 저장
//    // - update 시점에 호출
//    // - 저장 포맷(JSON)과 위치를 한 곳에서 관리하기 위함
//    func saveToStorage(_ user: SessionUser) {
//        let data = try? JSONEncoder().encode(user)
//        storage.set(data, forKey: Key.user)
//    }
//}
//
//// MARK: - Public
//public extension UserSession {
//    
//    // 외부에 노출되는 세션 유저
//    // - cachedUser를 그대로 반환하는 read-only facade
//    // - 내부 구현(storage, cache)을 숨김
//    var sessionUser: SessionUser? {
//        cachedUser
//    }
//    
//    // 로그인 여부 판단
//    // - 계산 속성은 facade(sessionUser)가 아닌
//    // - single source of truth(cachedUser)를 기준으로 판단
//    var isLoggedIn: Bool {
//        self.cachedUser != nil
//    }
//    
//    var hasGroup: Bool {
//        self.cachedUser?.groupId != nil
//    }
//    
//    // 세션 변경 구독
//    // - handler를 등록하고
//    // - 현재 상태를 즉시 한 번 전달
//    func bind(_ handler: @escaping SessionChangeHandler) {
//        self.onSessionChanged = handler
//        handler(sessionUser)
//    }
//    
//    // 이후 변화 감지
//    func observe(_ handler: @escaping SessionChangeHandler) {
//        self.onSessionChanged = handler
//    }
//    
//    // 로그인 / 세션 갱신
//    // - 메모리 캐시 갱신
//    // - storage에 영속화
//    // - 구독 중인 외부 객체에 변경 알림
//    func update(_ user: SessionUser) {
//        self.cachedUser = user
//        self.saveToStorage(user)
//        self.onSessionChanged?(user) // 상태가 바뀌면 값을 만들어서 호출 -> 받는쪽:  bind로 등록한 외부 객체
//        Logger.d("\(String(describing: self.cachedUser ?? nil))")
//    }
//    
//    // 로그아웃 / 세션 초기화
//    // - 메모리 캐시 제거
//    // - storage 데이터 제거
//    // - 구독 중인 외부 객체에 nil 전달
//    func clear() {
//        cachedUser = nil
//        storage.remove(Key.user)
//        onSessionChanged?(nil)
//    }
//}
//
//extension UserSession {
//    
//    /// SessionUser에서 "변경을 허용하는 속성"만 명시적으로 관리
//    ///
//    /// - 목적:
//    ///   - userId 같은 불변 필드 수정 방지
//    ///   - KeyPath 기반 API의 무결성 확보
//    public func isAllowedKeyPath<Value>(
//        _ keyPath: WritableKeyPath<SessionUser, Value>
//    ) -> Bool {
//
//        switch keyPath {
//
//        // ✅ groupId는 세션 생명주기 중 변경 가능
//        case \SessionUser.groupId, \SessionUser.userId:
//            return true
//
//        // ❌ 그 외 모든 KeyPath는 차단
//        default:
//            return false
//        }
//    }
//    
//    /// SessionUser의 특정 속성만 업데이트한다.
//    ///
//    /// - Parameters:
//    ///   - keyPath: 수정하려는 SessionUser의 속성 KeyPath
//    ///   - value: 새로 설정할 값
//    ///
//    /// ⚠️ 주의
//    /// - 모든 KeyPath를 허용하지 않는다
//    /// - 반드시 `isAllowedKeyPath`를 통과해야 한다
//    /// - 변경은 storage 저장 + observer 알림까지 포함한다
//    public func update<Value>(
//        _ keyPath: WritableKeyPath<SessionUser, Value>,
//        _ value: Value
//    ) {
//        // 현재 로그인된 세션이 없으면 무시
//        guard var current = cachedUser else {
//            Logger.d("세션 없음")
//            return
//        }
//
//        // 🔐 허용되지 않은 KeyPath 차단
//        guard isAllowedKeyPath(keyPath) else {
//            // 개발 중 실수 즉시 발견하기 위함
//            assertionFailure("❌ This SessionUser keyPath is not allowed to be updated.")
//            return
//        }
//
//        // 실제 값 변경 (여기서는 groupId만 통과 가능)
//        current[keyPath: keyPath] = value
//
//        // single source of truth 갱신
//        cachedUser = current
//
//        // 변경된 세션을 영속화
//        saveToStorage(current)
//
//        // 세션 변경 이벤트 전파
//        onSessionChanged?(current)
//    }
//}
