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
    public var onCommentTapped: (() -> Void)?
    public var onImagePreviewTapped: ((String) -> Void)?
    
    @Dependency private var userSession: UserSession
    public var currentPost: Post {
        postRelay.value
    }
    private let groupUsecase: GroupUsecaseProtocol
    private let disposeBag = DisposeBag()
    private let postRelay: BehaviorRelay<Post>

    
    public struct Input {
        let imageTapped: Observable<Void>
        let commentButtonTapped: Observable<Void>
        let reload: Observable<Void>
    }
    
    public struct Output {
        let commentCount: Driver<Int>
    }
    
    public init (groupUsecase: GroupUsecaseProtocol, post: Post) {
        self.groupUsecase = groupUsecase
        self.postRelay = BehaviorRelay(value: post)
    }
    

    public func transform(input: Input) -> Output {
        
        input.imageTapped
            .bind(with: self, onNext: { owner, _ in
                owner.onImagePreviewTapped?(owner.currentPost.imageURL)
            }).disposed(by: disposeBag)
        
        input.commentButtonTapped
            .bind(with: self, onNext: { owner, _ in
                owner.onCommentTapped?()
            }).disposed(by: disposeBag)
        
        let commentCount = postRelay
            .map { $0.comments.count }
            .asDriver(onErrorJustReturn: 0)
        
        
        input.reload
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.groupUsecase.loadAndFetchGroup()
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
        
        return Output(commentCount: commentCount)
    }
}




