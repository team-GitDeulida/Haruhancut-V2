//
//  GroupUsecase.swift
//  Domain
//
//  Created by 김동현 on 2/5/26.
//

import RxSwift
import Core
import UIKit

enum DomainError: Error {
    case missingGroupId
}

public protocol GroupUsecaseProtocol {
    // Group
    // func createGroup(groupName: String) -> Single<(groupId: String, inviteCode: String)>
    // func joinGroup(inviteCode: String) -> Single<HCGroup>
    func updateGroup(path: String, post: Post) -> Single<Void>
    // func updateUserGroupId(groupId: String) -> Single<Void>
    func fetchGroup() -> Single<HCGroup>
    
    // Image
    func uploadImage(image: UIImage, path: String) -> Single<URL>
    func deleteImage(path: String) -> Single<Void>
    
    // Comment
    func addComment(path: String, value: Comment) -> Single<Void>
    func deleteComment(path: String) -> Single<Void>
    
    // Other
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Single<Void>
    
    // 시나리오
    func joinAndUpdateGroup(inviteCode: String) -> Single<Void>
    func createAndUpdateGroup(groupName: String) -> Single<Void>
}

public final class GroupUsecaseImpl: GroupUsecaseProtocol {
    private let groupRepository: GroupRepositoryProtocol
    private let userSession: UserSessionType
    
    public init(groupRepository: GroupRepositoryProtocol,
                userSession: UserSessionType
    ) {
        self.groupRepository = groupRepository
        self.userSession = userSession
    }
    
    // Group
    public func updateGroup(path: String, post: Post) -> Single<Void> {
        return groupRepository.updateGroup(path: path, post: post)
    }
    
    public func fetchGroup() -> Single<HCGroup> {
        guard let groupId = userSession.sessionUser?.groupId else {
            return .error(DomainError.missingGroupId)
        }
        return groupRepository.fetchGroup(groupId: groupId)
    }
    
    // Image
    public func uploadImage(image: UIImage, path: String) -> Single<URL> {
        return groupRepository.uploadImage(image: image, path: path)
    }
    
    public func deleteImage(path: String) -> Single<Void> {
        return groupRepository.deleteImage(path: path)
    }
    
    // Comment
    public func addComment(path: String, value: Comment) -> Single<Void> {
        return groupRepository.addComment(path: path, value: value)
    }
    
    public func deleteComment(path: String) -> Single<Void> {
        return groupRepository.deleteComment(path: path)
    }
    
    // Other
    public func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return groupRepository.observeValueStream(path: path, type: type)
    }
    
    public func deleteValue(path: String) -> Single<Void> {
        return groupRepository.deleteValue(path: path)
    }
    
    // 시나리오
    public func joinAndUpdateGroup(inviteCode: String) -> Single<Void> {
        groupRepository.joinGroup(inviteCode: inviteCode)                      // Single<HCGroup>
            .flatMap { group in
                self.groupRepository.updateUserGroupId(groupId: group.groupId) // Single<Void>
            }
    }
    
    public func createAndUpdateGroup(groupName: String) -> Single<Void> {
        groupRepository.createGroup(groupName: groupName)
            .flatMap { group in
                self.groupRepository.updateUserGroupId(groupId: group.groupId)
            }
    }
}
