//
//  FeedDetailViewModel.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import Foundation
import RxSwift
import Domain
import RxRelay
import RxCocoa
import Core
import HomeFeatureV2Interface
import UIKit

public final class FeedDetailViewModel: FeedDetailViewModelType {

    public var onCommentTapped: ((Post) -> Void)?
    public var onImagePreviewTapped: ((String) -> Void)?

    private let groupLoader: HomeGroupLoader
    private let disposeBag = DisposeBag()
    private let postRelay: BehaviorRelay<Post>

    public struct Input {
        let imageTapped: Observable<Void>
        let commentButtonTapped: Observable<Void>
        let reload: Observable<Void>
    }

    public struct Output {
        let imageURL: Driver<String>
        let commentCount: Driver<Int>
    }

    public init(groupUsecase: GroupUsecaseProtocol, post: Post) {
        self.groupLoader = .make(
            mode: .currentGroup,
            groupUsecase: groupUsecase
        )
        self.postRelay = BehaviorRelay(value: post)
    }

    init(
        groupLoader: HomeGroupLoader,
        post: Post
    ) {
        self.groupLoader = groupLoader
        self.postRelay = BehaviorRelay(value: post)
    }

    public func transform(input: Input) -> Output {
        input.imageTapped
            .bind(with: self, onNext: { owner, _ in
                owner.onImagePreviewTapped?(owner.postRelay.value.imageURL)
            }).disposed(by: disposeBag)

        input.commentButtonTapped
            .withLatestFrom(postRelay)
            .bind(with: self, onNext: { owner, post in
                owner.onCommentTapped?(post)
            }).disposed(by: disposeBag)

        let imageURL = postRelay
            .map(\.imageURL)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: postRelay.value.imageURL)

        let commentCount = postRelay
            .map { $0.comments.count }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)

        // 화면에 들어올 때 한 번 조회하고, 저장된 그룹이 바뀌면(댓글 작성·삭제 등) 바로 다시 그린다
        let reloadedGroup = input.reload
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.groupLoader.values()
            }
        let storedGroupChanges = groupLoader.changes()
            .catch { _ in .empty() }

        Observable.merge(reloadedGroup, storedGroupChanges)
            .withUnretained(self)
            .map { owner, group -> Post? in
                group.postsByDate
                    .values
                    .flatMap { $0 }
                    .first { $0.postId == owner.postRelay.value.postId }
            }
            .compactMap { $0 }
            .bind(to: postRelay)
            .disposed(by: disposeBag)

        return Output(imageURL: imageURL,
                      commentCount: commentCount)
    }
}
