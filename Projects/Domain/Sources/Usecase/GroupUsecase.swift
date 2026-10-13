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
    /// 저장된 그룹을 먼저 보내고, 저장된 그룹이 바뀔 때마다 보냅니다. 서버에는 묻지 않습니다.
    func observeGroup() -> Observable<HCGroup>
    /// 저장된 그룹을 먼저 보내고 서버 그룹으로 갱신하며 조회 단계를 보냅니다. 최근에 받은 그룹이면 서버를 건너뜁니다.
    func fetchGroupResult() -> Observable<FetchResult<HCGroup>>
    /// 서버 그룹만 다시 받아 저장하며 조회 단계를 보냅니다. 당겨서 새로고침할 때 씁니다.
    func refreshGroupResult() -> Observable<FetchResult<HCGroup>>
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

public extension GroupUsecaseProtocol {
    /// 구독을 지원하지 않는 Demo·테스트 구현을 위한 기본 동작입니다. 조회한 그룹만 보냅니다.
    func observeGroup() -> Observable<HCGroup> {
        loadAndFetchGroup()
    }

    /// 조회 단계를 지원하지 않는 Demo·테스트 구현을 위한 기본 동작입니다. 조회한 그룹을 성공으로 보냅니다.
    func fetchGroupResult() -> Observable<FetchResult<HCGroup>> {
        loadAndFetchGroup()
            .map { FetchResult(status: .success, value: $0) }
            .catch { error in
                .just(FetchResult(status: .failure(error), value: nil))
            }
    }

    /// 조회 단계를 지원하지 않는 Demo·테스트 구현을 위한 기본 동작입니다. `fetchGroupResult()`와 같습니다.
    func refreshGroupResult() -> Observable<FetchResult<HCGroup>> {
        fetchGroupResult()
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
    /// 같은 그룹 요청을 합치고, 10초 안에 받은 그룹이면 `fetch`가 서버를 건너뛰게 한다
    private let groupRequests = FetchRequests<HCGroup>(maxAge: 10)
    
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
        fetchGroupResult()
            .fetchedValues()
    }

    public func observeGroup() -> Observable<HCGroup> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }

        return groupFetcher(groupId: groupId)
            .observe()
            .compactMap { $0 }
    }

    public func fetchGroupResult() -> Observable<FetchResult<HCGroup>> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }

        return groupFetcher(groupId: groupId)
            .fetch()
    }

    public func refreshGroupResult() -> Observable<FetchResult<HCGroup>> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingGroupId)
        }

        return groupFetcher(groupId: groupId)
            .refresh()
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
        let groupRepository = groupRepository

        // 저장된 그룹에 댓글을 먼저 넣고 서버에 쓴다. 실패하면 Fetcher가 되돌린다
        return writeGroup(groupId: groupId, change: { group in
            group.updatePost(post) { $0.comments[commentId] = newComment }
        }, write: {
            groupRepository.addComment(path: path, value: newComment)
        })
    }

    public func deleteComment(post: Post, commentId: String) -> Single<Void> {
        guard let groupId = userSession.groupId else {
            return .error(DomainError.missingDomainSession)
        }
        
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        let groupRepository = groupRepository

        // 저장된 그룹에서 댓글을 먼저 빼고 서버에서 지운다. 실패하면 Fetcher가 되돌린다
        return writeGroup(groupId: groupId, change: { group in
            group.updatePost(post) { $0.comments[commentId] = nil }
        }, write: {
            groupRepository.deleteComment(path: path)
        })
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
                
                // 저장된 그룹에 게시물을 먼저 넣고 서버에 쓴다. 실패하면 Fetcher가 되돌린다
                return self.writeGroup(groupId: groupId, change: { group in
                    group.appendPost(post)
                }, write: {
                    self.groupRepository.updateGroup(path: dbPath, post: post)
                })
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
        let groupRepository = groupRepository

        // 저장된 그룹에서 게시물을 먼저 빼고 서버에서 지운다. 실패하면 Fetcher가 되돌린다
        return writeGroup(groupId: groupId, change: { group in
            group.removePost(post)
        }, write: {
            groupRepository.deleteImage(path: storagePath)
                .catch { _ in .just(()) }   // 스토리지 삭제 실패는 무시하고 계속 진행
                .flatMap { groupRepository.deleteValue(path: dbPath) }
        })
        .asObservable()
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
    /// - 서버에 그룹이 없으면 그룹 캐시를 지우고, 서버와 세션의 groupId도 지운다 (`leaveMissingGroup`)
    /// - 15초 안에 응답이 없으면 실패로 보고, 같은 그룹 요청은 하나로 합친다
    func groupFetcher(groupId: String) -> Fetcher<HCGroup> {
        let userSession = userSession
        let groupSession = groupSession
        let groupRepository = groupRepository

        return Fetcher(
            local: { groupSession.entity },
            observeLocal: {
                groupSession.asObservable()
                    .map { $0?.toEntity() }
            },
            remote: { groupRepository.fetchGroup(groupId: groupId) },
            updateLocal: { group in
                groupSession.update(group.toSession())
            },
            removeLocal: {
                groupSession.clear()
            },
            cleanUpNotFound: {
                self.leaveMissingGroup(groupId: groupId)
            },
            // 다른 그룹으로 바뀐 뒤 늦게 온 응답은 버린다
            isCurrent: { userSession.groupId == groupId }
        )
        .timeout(.seconds(15))
        .sharing(groupRequests, key: groupId)
        .logging("Group")
    }

    /// 저장된 그룹을 먼저 바꾸고 서버에 쓴다. 서버 쓰기가 실패하면 Fetcher가 되돌린다
    /// - 저장된 그룹이 없으면(첫 실행, 저장 실패 등) 바꿀 캐시가 없으므로 서버에만 쓴다. 다음 조회가 서버에서 받아 온다
    func writeGroup(
        groupId: String,
        change: @escaping (inout HCGroup) -> Void,
        write: @escaping () -> Single<Void>
    ) -> Single<Void> {
        Single.deferred {
            guard self.groupSession.entity != nil else {
                return write()
            }
            return self.groupFetcher(groupId: groupId)
                .update(change, remote: { _ in write() })
                .map { _ in () }
        }
    }

    /// 서버에 그룹이 없을 때 서버와 세션에서 유저의 groupId를 지운다
    /// - 서버의 groupId도 지워야 다음 유저 조회가 없는 그룹의 id를 세션에 되살리지 않는다
    /// - 세션의 groupId가 지워지면 AppCoordinator가 그룹 화면으로 보낸다
    func leaveMissingGroup(groupId: String) -> Completable {
        guard
            let userId = userSession.userId,
            userSession.groupId == groupId
        else {
            return .empty()
        }

        let userSession = userSession
        return groupRepository
            .deleteValue(path: "users/\(userId)/groupId")
            .do(onSuccess: {
                // 지우는 동안 다른 그룹으로 바뀌었으면 세션을 바꾸지 않는다
                guard userSession.groupId == groupId else { return }
                userSession.update(\.groupId, nil)
            })
            .asCompletable()
    }
}

// MARK: - 저장된 그룹 고치기
private extension HCGroup {
    /// 게시물 하나를 바꾼다. 저장된 그룹에 그 게시물이 없으면 아무것도 하지 않는다
    mutating func updatePost(_ post: Post, _ change: (inout Post) -> Void) {
        let dateKey = post.createdAt.toDateKey()
        guard let index = postsByDate[dateKey]?.firstIndex(where: { $0.postId == post.postId }) else {
            return
        }
        change(&postsByDate[dateKey]![index])
    }

    /// 게시물을 넣는다
    mutating func appendPost(_ post: Post) {
        postsByDate[post.createdAt.toDateKey(), default: []].append(post)
    }

    /// 게시물을 뺀다. 날짜 폴더가 비면 서버처럼 폴더도 지운다
    mutating func removePost(_ post: Post) {
        let dateKey = post.createdAt.toDateKey()
        postsByDate[dateKey]?.removeAll { $0.postId == post.postId }
        if postsByDate[dateKey]?.isEmpty == true {
            postsByDate[dateKey] = nil
        }
    }
}
