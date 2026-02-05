//
//  GroupUsecase.swift
//  Domain
//
//  Created by 김동현 on 2/5/26.
//

import RxSwift
import Core
import UIKit

public protocol GroupUsecaseProtocol {
    // Group
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
    func updateGroup(path: String, post: Post) -> Observable<Result<Void, GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    
    // Image
    func uploadImage(image: UIImage, path: String) -> Observable<Result<URL, GroupError>>
    func deleteImage(path: String) -> Observable<Result<Void, GroupError>>
    
    // Comment
    func addComment(path: String, value: Comment) -> Observable<Result<Void, GroupError>>
    func deleteComment(path: String) -> Observable<Result<Void, GroupError>>
    
    // Other
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<Result<T, GroupError>>
    func deleteValue(path: String) -> Observable<Result<Void, GroupError>>
    
    // custom
    // func joinAndUpdateGroup(inviteCode: String) -> Observable<Void>
}

public final class GroupUsecaseImpl: GroupUsecaseProtocol {
    private let groupRepository: GroupRepositoryProtocol
    
    public init(groupRepository: GroupRepositoryProtocol) {
        self.groupRepository = groupRepository
    }
    
    // Group
    public func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return groupRepository.createGroup(groupName: groupName)
    }
    public func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        return groupRepository.joinGroup(inviteCode: inviteCode)
    }
    
    public func updateGroup(path: String, post: Post) -> Observable<Result<Void, GroupError>> {
        return groupRepository.updateGroup(path: path, post: post)
    }
    
    public func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
        return groupRepository.updateUserGroupId(groupId: groupId)
    }
    
    public func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        return groupRepository.fetchGroup(groupId: groupId)
    }
    
    // Image
    public func uploadImage(image: UIImage, path: String) -> Observable<Result<URL, GroupError>> {
        return groupRepository.uploadImage(image: image, path: path)
    }
    
    public func deleteImage(path: String) -> Observable<Result<Void, GroupError>> {
        return groupRepository.deleteImage(path: path)
    }
    
    // Comment
    public func addComment(path: String, value: Comment) -> Observable<Result<Void, GroupError>> {
        return groupRepository.addComment(path: path, value: value)
    }
    
    public func deleteComment(path: String) -> Observable<Result<Void, GroupError>> {
        return groupRepository.deleteComment(path: path)
    }
    
    // Other
    public func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<Result<T, GroupError>> {
        return groupRepository.observeValueStream(path: path, type: type)
    }
    
    public func deleteValue(path: String) -> Observable<Result<Void, GroupError>> {
        return groupRepository.deleteValue(path: path)
    }
    
//    public func joinAndUpdateGroup(inviteCode: String) -> Observable<Void> {
//
//    }
}
