//
//  FeedDetailViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 2/11/26.
//

import Foundation
import RxSwift
import Domain
import RxRelay
import RxCocoa
import Core
import Data
import HomeFeatureInterface

public final class FeedDetailViewModel: FeedDetailViewModelType {
    public var onCommentTapped: (() -> Void)?
    
    @Dependency private var userSession: UserSessionType
    private var currentUserId: String? {
        return userSession.sessionUser?.userId
    }
    private var currentGroupId: String? {
        return userSession.sessionUser?.groupId
    }
    public var currentPost: Post {
        postRelay.value
    }
    private let groupUsecase: GroupUsecaseProtocol
    private let disposeBag = DisposeBag()
    private let postRelay: BehaviorRelay<Post>

    
    public struct Input {
        let sendTap: Observable<String>
        let deleteTap: Observable<String>
    }
    
    public struct Output {
        let comments: Driver<[Comment]>
        let sendResult: Driver<Bool>
        let deleteResult: Driver<Bool>
    }
    
    public init (groupUsecase: GroupUsecaseProtocol, post: Post) {
        self.groupUsecase = groupUsecase
        self.postRelay = BehaviorRelay(value: post)
    }
    
    public func transform(input: Input) -> Output {
        let comments = postRelay
            .map { post in
                post.comments
                    .sorted(by: { $0.value.createdAt < $1.value.createdAt })
                    .map { $0.value }
            }
            .asDriver(onErrorJustReturn: [])
        
        let sendResult = input.sendTap
            .flatMapLatest { [weak self] text -> Driver<Bool> in
                guard let self = self else { return .just(false) }
                print("🔥 ViewModel sendTap triggered with:", text)
                return self.addComment(post: self.currentPost, text: text)
            }.asDriver(onErrorJustReturn: false)
        
//        let sendResult = input.sendTap
//            .flatMapLatest { text -> Driver<Bool> in
//                guard let self = self else { return .just(false)}
//                return self.addComment(text: text)
//                    .asDriver(onErrorJustReturn: false)
//            }
//        
//        let deleteResult = input.deleteTap
//            .flatMapLatest { [weak self] commentId -> Driver<Bool> in
//                guard let self else { return .just(false) }
//                return self.deleteComment(commentId: commentId)
//                    .asDriver(onErrorJustReturn: false)
//            }
        
        return Output(comments: comments, sendResult: sendResult, deleteResult: .just(false))
    }
    
    func addComment(post: Post, text: String) -> Driver<Bool> {
        guard let userId = currentUserId, let groupId = currentGroupId else {
            return .just(false)
        }
        let commentId = UUID().uuidString
        let newComment = Comment(commentId: commentId,
                                 userId: userId,
                                 nickname: "",
                                 profileImageURL: "",
                                 text: text,
                                 createdAt: Date())
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        
        return self.groupUsecase.addComment(path: path, value: newComment)
            .map { true } // Void -> Bool
            .asDriver(onErrorJustReturn: false)
    }
}
