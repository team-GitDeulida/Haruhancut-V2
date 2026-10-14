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
    private let disposeBag = DisposeBag()
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

        // 저장된 그룹이 바뀌면 이 게시물의 댓글을 다시 그린다.
        // 댓글 작성·삭제는 저장된 그룹을 먼저 바꾸고, 실패하면 되돌리므로 여기서 따로 되돌리지 않는다
        let postId = postRelay.value.postId
        groupUsecase.observeGroup()
            .compactMap { group in
                group.postsByDate
                    .values
                    .flatMap { $0 }
                    .first { $0.postId == postId }
            }
            .catch { _ in .empty() }
            .bind(to: postRelay)
            .disposed(by: disposeBag)

        let sendResult = input.sendTap
            .withUnretained(self)
            .concatMap { owner, text -> Observable<Bool> in
                owner.groupUsecase
                    .addComment(post: owner.postRelay.value, text: text)
                    .map { true }
                    .asObservable()
                    .catchAndReturn(false)
            }
            .asDriver(onErrorJustReturn: false)

        let deleteResult = input.deleteTap
            .withUnretained(self)
            .concatMap { owner, commentId -> Observable<Bool> in
                owner.groupUsecase
                    .deleteComment(post: owner.postRelay.value, commentId: commentId)
                    .map { true }
                    .asObservable()
                    .catchAndReturn(false)
            }
            .asDriver(onErrorJustReturn: false)

        return Output(comments: comments,
                      sendResult: sendResult,
                      deleteResult: deleteResult)
    }
}
