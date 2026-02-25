//
//  CalendarDetailViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 2/24/26.
//

import UIKit
import Domain
import RxSwift
import RxRelay
import RxCocoa
import HomeFeatureInterface

public final class CalendarDetailViewModel: CalendarDetailViewModelType {
    
    // MARK: - Coordinator Trigger
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

        /*
         A.withLatestFrom(B)
         - A가 이벤트를 발생시킬 때 B의 최근 값을 가져온다
         - currentIndex가 바뀌는 순간 postRelay의 posts 배열을 가져온다
         - (index, posts)
         
         combineLatest는 A나 B둘중 하나라도 바뀌면 실행됨
         withLatestFrom은 A가 바뀔 때만 실행됨
         */
        /*
        let commentCount = input.currentIndex
            .withLatestFrom(postsRelay) { index, posts -> Int in
                guard posts.indices.contains(index) else { return 0 }
                return posts[index].comments.count
            }.asDriver(onErrorJustReturn: 0)
         */
        
        // 둘중 하나라도 방출되야 하기떄문에 combineLatest 사용
        let commentCount = Observable
            .combineLatest(input.currentIndex, postsRelay) { index, posts -> Int in
                guard posts.indices.contains(index) else { return 0 }
                return posts[index].comments.count
            }
            .asDriver(onErrorJustReturn: 0)
        
        input.reload
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<HCGroup> in
                owner.groupUsecase.loadAndFetchGroup()
                    .catch { _ in .empty() } // 추후에 에러 상세 처리 예정
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
