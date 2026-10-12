//
//  GroupUsecase.swift
//  Domain
//
//  Created by 김동현 on 2/5/26.
//

import RxSwift
import Core
import UIKit

public enum DomainError: Error {
    case missingGroupId
    case missingDomainSession
    case userNotFound
    case groupNotFound
    case groupMemberPermissionRequired
    case adminPermissionRequired
}

public protocol GroupUsecaseProtocol {
    func updateGroup(path: String, post: Post) -> Single<Void>
    func updateBirthdaySettings(
        _ settings: GroupBirthdaySettings
    ) -> Single<Void>
    
    
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
    func deletePostAndReload(post: Post) -> Observable<Void>

    #if DEBUG
    func resetPostsForUITests() -> Single<Int>
    #endif
}

public extension GroupUsecaseProtocol {
    /// 생일 설정을 사용하지 않는 Demo 구현을 위한 기본 동작입니다.
    func updateBirthdaySettings(
        _ settings: GroupBirthdaySettings
    ) -> Single<Void> {
        .error(
            DomainError
                .missingDomainSession
        )
    }
}

#if DEBUG
public extension GroupUsecaseProtocol {
    /// 실제 저장소를 사용하지 않는 Demo 구현을 위한 기본 동작입니다.
    func resetPostsForUITests() -> Single<Int> {
        .just(0)
    }
}
#endif

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

    public func updateBirthdaySettings(
        _ settings: GroupBirthdaySettings
    ) -> Single<Void> {
        guard
            let group =
                groupSession.session,
            let userId =
                userSession.userId
        else {
            return .error(
                DomainError
                    .missingDomainSession
            )
        }
        guard
            group.members[userId] != nil
        else {
            return .error(
                DomainError
                    .groupMemberPermissionRequired
            )
        }

        return groupRepository
            .updateBirthdaySettings(
                groupId: group.groupId,
                settings: settings
            )
            .do(onSuccess: {
                [weak self] in
                self?.groupSession.update(
                    \.birthdaySettings,
                    settings
                )
            })
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
    
    /// 캐시된 그룹을 먼저 보내고 서버 그룹으로 갱신한다
    /// - 서버에 그룹이 없으면 그룹 캐시와 유저의 groupId(서버·세션)를 지우고 `FetchError.notFound`로 끝낸다
    /// - 서버에 확인하지 못하면 캐시를 유지하고 그 에러로 끝낸다
    public func loadAndFetchGroup() -> Observable<HCGroup> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }

        return groupFetcher(groupId: groupId)
            .fetch()
            .concatMap { self.leaveGroupIfNotFound($0, groupId: groupId) }
            .fetchedValues()
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

    public func deleteComment(post: Post, commentId: String) -> Single<Void> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingDomainSession)
        }
        
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        return self.groupRepository.deleteComment(path: path)
    }
    
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
    }
    
    public func deletePostAndReload(post: Post) -> Observable<Void> {
        guard let groupId = userSession.groupId else {
            return .deferred { .error(DomainError.missingDomainSession) }
        }
        
        let dateKey = post.createdAt.toDateKey()
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)"
        let storagePath = "groups/\(groupId)/images/\(post.postId).jpg"
        
        return groupRepository.deleteImage(path: storagePath)
            .catch { _ in .just(()) }   // 스토리지 삭제 실패는 무시하고 계속 진행
            .flatMap {
                self.groupRepository.deleteValue(path: dbPath)
            }.asObservable()
            .flatMap { _ in
                // 삭제가 반영된 서버 그룹만 다시 받아 세션에 저장
                self.groupFetcher(groupId: groupId)
                    .refresh()
                    .concatMap { self.leaveGroupIfNotFound($0, groupId: groupId) }
                    .fetchedValues()
            }
            .mapToVoid()
    }

    #if DEBUG
    public func resetPostsForUITests() -> Single<Int> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }

        let repository = groupRepository

        return repository
            .fetchGroup(groupId: groupId)
            .flatMap { [weak self] group -> Single<Int> in
                guard let group else {
                    return .error(DomainError.groupNotFound)
                }

                let posts = group.postsByDate.values.flatMap { $0 }
                let postsPath = "groups/\(groupId)/postsByDate"

                let deleteImages = Observable
                    .from(posts)
                    .flatMap { post in
                        repository
                            .deleteImage(
                                path: "groups/\(groupId)/images/\(post.postId).jpg"
                            )
                            .asObservable()
                            .catch { error in
                                Logger.w(
                                    "UI 테스트 이미지 정리 실패: \(post.postId), \(error)"
                                )
                                return .just(())
                            }
                    }
                    .toArray()
                    .map { _ in () }

                return repository
                    .deleteValue(path: postsPath)
                    .flatMap { deleteImages }
                    .do(onSuccess: {
                        self?.groupSession.update(
                            \.postsByDate,
                            [:]
                        )
                    })
                    .map { posts.count }
            }
    }
    #endif
}

// MARK: - Fetcher
private extension GroupUsecaseImpl {
    /// 그룹 세션과 서버 그룹을 맞추는 Fetcher
    /// - 서버에 그룹이 없으면 그룹 캐시를 지운다. 유저의 groupId는 `leaveGroupIfNotFound`가 지운다
    func groupFetcher(groupId: String) -> Fetcher<HCGroup> {
        let userSession = userSession
        let groupSession = groupSession
        let groupRepository = groupRepository

        return Fetcher(
            local: { groupSession.entity },
            remote: { groupRepository.fetchGroup(groupId: groupId) },
            updateLocal: { group in
                groupSession.update(group.toSession())
            },
            removeLocal: {
                // 다른 그룹으로 바뀐 뒤 늦게 온 응답이면 지우지 않는다
                guard userSession.groupId == groupId else { return }
                groupSession.clear()
            }
        )
    }

    /// 서버에 그룹이 없으면 서버와 세션에서 유저의 groupId를 지운 뒤 결과를 그대로 보낸다
    /// - 서버의 groupId도 지워야 다음 유저 조회가 없는 그룹의 id를 세션에 되살리지 않는다
    /// - 세션의 groupId가 지워지면 AppCoordinator가 그룹 화면으로 보낸다
    func leaveGroupIfNotFound(
        _ result: FetchResult<HCGroup>,
        groupId: String
    ) -> Observable<FetchResult<HCGroup>> {
        guard
            case .notFound = result.status,
            let userId = userSession.userId,
            userSession.groupId == groupId
        else {
            return .just(result)
        }

        let userSession = userSession
        return groupRepository
            .deleteValue(path: "users/\(userId)/groupId")
            .do(onSuccess: {
                // 지우는 동안 다른 그룹으로 바뀌었으면 세션을 바꾸지 않는다
                guard userSession.groupId == groupId else { return }
                userSession.update(\.groupId, nil)
            })
            .map { result }
            .asObservable()
    }
}
