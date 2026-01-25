//
//  UserSession.swift
//  Core
//
//  Created by 김동현 on 1/13/26.
//

//import Foundation
//
//public protocol UserSessionType: AnyObject {
//    
//    /// 로그인된 유저
//    /// - nil: 로그아웃 상태
//    /// - User: 로그인 상태
//    var currentUser: User? { get }
//    
//    /// 유저 상태 변경 이벤트 콜백
//    /// - 변경되었다는 사실만 외부로 알리기 위함
//    var onUserChanged: ((User?) -> Void)? { get set }
//    
//    /// 현재 유저를 갱신
//    /// - 로그인 성공 시 User 전달
//    /// - 로그아웃시: nil 전달
//    func update(user: User?)
//}
//
//public final class UserSession: UserSessionType {
//    
//    public var currentUser: User?
//    
//    public var onUserChanged: ((User?) -> Void)?
//    
//    public init() {}
//    
//    public func update(user: User?) {
//        currentUser = user
//        onUserChanged?(user)
//    }
//}
