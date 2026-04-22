//
//  CommentViewModel.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import RxSwift
import RxCocoa
import Domain

public final class CommentViewModel {

    private let groupUsecase: GroupUsecaseProtocol
    private let postRelay: BehaviorRelay<Post>
    public var currentPost: Post {
        postRelay.value
    }

    public struct Input {
        let sendTap: Observable<String>
        let deleteTap: Observable<String>
    }

    public struct Output {
        let comments: Driver<[Comment]>
        let sendResult: Driver<Bool>
        let deleteResult: Driver<Bool>
    }

    public init(groupUsecase: GroupUsecaseProtocol, post: Post) {
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
            .withUnretained(self)
            .concatMap { owner, text -> Observable<Bool> in
                owner.groupUsecase
                    .addComment(post: owner.postRelay.value, text: text)
                    .asObservable()
                    .withUnretained(self)
                    .flatMapLatest { owner, _ in
                        owner.groupUsecase.loadAndFetchGroup()
                    }
                    .withUnretained(self)
                    .map { owner, group in
                        if let updatedPost = group.postsByDate
                            .values
                            .flatMap({ $0 })
                            .first(where: { $0.postId == owner.postRelay.value.postId }) {
                            owner.postRelay.accept(updatedPost)
                        }
                        return true
                    }
            }
            .asDriver(onErrorJustReturn: false)

        let deleteResult = input.deleteTap
            .withUnretained(self)
            .concatMap { owner, commentId -> Observable<Bool> in
                let originalPost = owner.postRelay.value

                var updatedPost = originalPost
                updatedPost.comments.removeValue(forKey: commentId)
                owner.postRelay.accept(updatedPost)

                return owner.groupUsecase
                    .deleteComment(post: originalPost, commentId: commentId)
                    .asObservable()
                    .withUnretained(self)
                    .flatMapLatest { owner, _ in
                        owner.groupUsecase.loadAndFetchGroup()
                            .takeLast(1)
                    }
                    .withUnretained(self)
                    .map { owner, group in
                        if let refreshedPost = group.postsByDate
                            .values
                            .flatMap({ $0 })
                            .first(where: { $0.postId == originalPost.postId }) {
                            owner.postRelay.accept(refreshedPost)
                        }
                        return true
                    }
                    .catch { _ in
                        owner.postRelay.accept(originalPost)
                        return .just(false)
                    }
            }
            .asDriver(onErrorJustReturn: false)

        return Output(comments: comments,
                      sendResult: sendResult,
                      deleteResult: deleteResult)
    }
}
