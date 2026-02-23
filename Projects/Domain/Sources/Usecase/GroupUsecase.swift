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
    case missingDomainSession
}

public protocol GroupUsecaseProtocol {
    func updateGroup(path: String, post: Post) -> Single<Void>
    
    
    // Other
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Single<Void>
    
    // 시나리오
    func joinAndUpdateGroup(inviteCode: String) -> Single<Void>
    func createAndUpdateGroup(groupName: String) -> Single<Void>
    func loadAndFetchGroup() -> Observable<HCGroup>
    func addComment(post: Post, text: String) -> Single<Void>
    func deleteComment(post: Post, commentId: String) -> Single<Void>
    func uploadImageAndUploadPost(image: UIImage) -> Observable<Void>
    func deletePost(post: Post) -> Single<Void>
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
    
    /// Fetches the group associated with the current user's session.
    /// - Returns: An `HCGroup` if a groupId exists for the current user; otherwise emits `DomainError.missingGroupId`.
    private func fetchGroup() -> Single<HCGroup> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }
        return groupRepository.fetchGroup(groupId: groupId)
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
              let nickname = userSession.nickname
        else {
            return .error(DomainError.missingDomainSession)
            // return .deferred { .just(()) } // 에러 없지만 아무 작업도 안함
        }
        
        let commentId = UUID().uuidString
        let profileImageURL = userSession.profileImageURL
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
    
    /// Deletes a comment from the specified post in the current user's group.
    ///
    /// If the current user has no `groupId` in session, the call is a no-op and completes without error.
    /// - Parameters:
    ///   - post: The post containing the comment; `post.createdAt` and `post.postId` are used to build the deletion path.
    ///   - commentId: The identifier of the comment to delete.
    /// - Returns: `Void` when the deletion completes successfully.
    public func deleteComment(post: Post, commentId: String) -> Single<Void> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingDomainSession)
        }
        
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        return self.groupRepository.deleteComment(path: path)
    }
    
    /// Uploads an image, creates a post that references the uploaded image, and refreshes the group's cached data.
    /// - Parameter image: The image to upload and attach to the new post.
    /// - Returns: `Void` if the upload, post creation, and group refresh complete successfully; emits an error otherwise.
    public func uploadImageAndUploadPost(image: UIImage) -> Observable<Void> {
        guard let userId = userSession.userId,
              let nickname = userSession.nickname,
              let groupId = userSession.groupId
        else {
            return .error(DomainError.missingDomainSession)
        }
        
        let postId = UUID().uuidString
        let now = Date()
        let dateKey = now.toDateKey()
        let profileImageURL = self.userSession.profileImageURL
        
        let storagePath = "groups/\(groupId)/images/\(postId).jpg"         // storage  저장 위치
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(postId)"  // realtime 저장 위치
        
        return groupRepository.uploadImage(image: image, path: storagePath)
            .asObservable()
            .flatMap { url -> Observable<Void> in
                let post = Post(postId: postId,
                                userId: userId,
                                nickname: nickname,
                                profileImageURL: profileImageURL,
                                imageURL: url.absoluteString,
                                createdAt: now,
                                likeCount: 0, // 추후 사용 예정
                                comments: [:])
                
                return self.groupRepository
                    .updateGroup(path: dbPath, post: post)
                    .asObservable()
            }
            .flatMap { _ in
                self.loadAndFetchGroup()
                    .mapToVoid()
            }
    }
    
    public func deletePost(post: Post) -> Single<Void> {
        guard let groupId = userSession.groupId else {
            return .deferred { .error(DomainError.missingDomainSession) }
        }
        
        let dateKey = post.createdAt.toDateKey()
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)"
        let storagePath = "groups/\(groupId)/images/\(post.postId).jpg"
        
        return groupRepository.deleteImage(path: storagePath)
            .flatMap {
                self.groupRepository.deleteValue(path: dbPath)
            }
    }
}
