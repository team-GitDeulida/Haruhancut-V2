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
    // func fetchGroup() -> Single<HCGroup>
    
    // Image
    func uploadImage(image: UIImage, path: String) -> Single<URL>
    func deleteImage(path: String) -> Single<Void>
    
    // Comment
    // func addComment(path: String, value: Comment) -> Single<Void>
    // func deleteComment(path: String) -> Single<Void>
    
    // Other
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Single<Void>
    
    // 시나리오
    func joinAndUpdateGroup(inviteCode: String) -> Single<Void>
    func createAndUpdateGroup(groupName: String) -> Single<Void>
    func loadAndFetchGroup() -> Observable<HCGroup>
    func addComment(post: Post, text: String) -> Single<Void>
    func deleteComment(post: Post, commentId: String) -> Single<Void>
}

public final class GroupUsecaseImpl: GroupUsecaseProtocol {
    private let groupRepository: GroupRepositoryProtocol
    private let userSession: UserSession
    private let groupSession: GroupSession
    
    public init(groupRepository: GroupRepositoryProtocol,
                userSession: UserSession,
                groupSession: GroupSession
    ) {
        self.groupRepository = groupRepository
        self.userSession = userSession
        self.groupSession = groupSession
    }
    
    // Group
    public func updateGroup(path: String, post: Post) -> Single<Void> {
        return groupRepository.updateGroup(path: path, post: post)
    }
    
    private func fetchGroup() -> Single<HCGroup> {
        guard let groupId = userSession.groupId else {
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
    private func addComment(path: String, value: Comment) -> Single<Void> {
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
    
    public func loadAndFetchGroup() -> Observable<HCGroup> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }
        
        // 1. 캐시 먼저 방출
        let cached = groupSession.entity
            .map { Observable.just($0) } ?? .empty()
        
        // 2. 서버
        let remote = groupRepository.fetchGroup(groupId: groupId)
            .do(onSuccess: { [weak self] group in
                // 서버 결과 세션에 캐시
                self?.groupSession.update(group.toSession())
            })
            .asObservable()

        // 3. 캐시 -> 서버 순서로 방출
        return Observable.concat(cached, remote)
            .enumerated()
            .do(onNext: { index, group in
                Logger.d("\n[\(index)]번째 방출: \(group.description)")
            })
            .map { $0.element }
    }
    
    
    public func addComment(post: Post, text: String) -> Single<Void> {
        guard let userId = userSession.userId,
              let groupId = userSession.groupId,
              let nickname = userSession.nickname,
              let profileImageURL = userSession.profileImageURL
        else {
            return .deferred { .just(()) }
        }
        let commentId = UUID().uuidString
        let newComment = Comment(commentId: commentId,
                                 userId: userId,
                                 nickname: nickname,
                                 profileImageURL: profileImageURL,
                                 text: text,
                                 createdAt: Date())
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        return self.groupRepository.addComment(path: path, value: newComment)
    }
    
    public func deleteComment(post: Post, commentId: String) -> Single<Void> {
        guard let groupId = userSession.groupId else {
            return .deferred { .just(()) }
        }
        
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        return self.groupRepository.deleteComment(path: path)
    }
}
