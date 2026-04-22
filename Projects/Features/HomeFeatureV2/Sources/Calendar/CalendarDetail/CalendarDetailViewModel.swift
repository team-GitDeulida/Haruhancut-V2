//
//  CalendarDetailViewModel.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import Domain
import RxSwift
import RxRelay
import RxCocoa
import HomeFeatureV2Interface

public final class CalendarDetailViewModel: CalendarDetailViewModelType {
    
    public var onCommentTapped: ((Post) -> Void)?
    public var onImagePreviewTapped: ((String) -> Void)?
    
    private let disposeBag = DisposeBag()
    private let groupUsecase: GroupUsecaseProtocol
    private let postsRelay: BehaviorRelay<[Post]>
    
    let selectedDate: Date
    public var posts: [Post] {
        postsRelay.value
    }
    
    public struct Input {
        let imageTapped: Observable<Post>
        let commentButtonTapped: Observable<Post>
        let currentIndex: Observable<Int>
        let reload: Observable<Void>
    }
    public struct Output {
        let posts: Driver<[Post]>
        let commentCount: Driver<Int>
    }
    
    public init(groupUsecase: GroupUsecaseProtocol, posts: [Post], selectedDate: Date) {
        self.groupUsecase = groupUsecase
        self.postsRelay = BehaviorRelay<[Post]>(value: posts)
        self.selectedDate = selectedDate
    }
    
    public func transform(input: Input) -> Output {
        input.imageTapped
            .bind(with: self, onNext: { owner, post in
                owner.onImagePreviewTapped?(post.imageURL)
            }).disposed(by: disposeBag)
        
        input.commentButtonTapped
            .bind(with: self, onNext: { owner, post in
                owner.onCommentTapped?(post)
            }).disposed(by: disposeBag)
        
        let commentCount = Observable
            .combineLatest(input.currentIndex, postsRelay) { index, posts -> Int in
                guard posts.indices.contains(index) else { return 0 }
                return posts[index].comments.count
            }
            .asDriver(onErrorJustReturn: 0)
        
        input.reload
            .withUnretained(self)
            .flatMap { owner, _ -> Observable<HCGroup> in
                owner.groupUsecase.loadAndFetchGroup()
                    .catch { _ in .empty() }
            }
            .withUnretained(self)
            .map { owner, group in
                group.postsByDate[owner.selectedDate.toDateKey()] ?? []
            }
            .bind(to: postsRelay)
            .disposed(by: disposeBag)
          
        return Output(posts: postsRelay.asDriver(),
                      commentCount: commentCount)
    }
}
