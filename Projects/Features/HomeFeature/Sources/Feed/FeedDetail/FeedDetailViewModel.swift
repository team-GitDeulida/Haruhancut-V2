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
import HomeFeatureInterface
import UIKit

public final class FeedDetailViewModel: FeedDetailViewModelType {
    
    // MARK: - Coordinator Trigger
    public var onCommentTapped: ((Post) -> Void)?
    public var onImagePreviewTapped: ((String) -> Void)?
    
    @Dependency private var userSession: UserSession
    private let groupUsecase: GroupUsecaseProtocol
    private let disposeBag = DisposeBag()
    private let postRelay: BehaviorRelay<Post>

    
    public struct Input {
        let imageTapped: Observable<Void>
        let commentButtonTapped: Observable<Void>
        let reload: Observable<Void>
    }
    
    public struct Output {
        let post: Driver<Post>
        let commentCount: Driver<Int>
    }
    
    public init (groupUsecase: GroupUsecaseProtocol, post: Post) {
        self.groupUsecase = groupUsecase
        self.postRelay = BehaviorRelay(value: post)
    }

    public func transform(input: Input) -> Output {
        
        // MARK: - Coordinator
        input.imageTapped
            .bind(with: self, onNext: { owner, _ in
                owner.onImagePreviewTapped?(owner.postRelay.value.imageURL)
            }).disposed(by: disposeBag)
        
        input.commentButtonTapped
            .withLatestFrom(postRelay)
            .bind(with: self, onNext: { owner, post in
                owner.onCommentTapped?(post)
            }).disposed(by: disposeBag)
        
        let commentCount = postRelay
            .map { $0.comments.count }
            .asDriver(onErrorJustReturn: 0)
        
        input.reload
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.groupUsecase.loadAndFetchGroup()
                    .catch { _ in .empty() }
            }
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
        
        return Output(post: postRelay.asDriver(),
                      commentCount: commentCount)
    }
}




