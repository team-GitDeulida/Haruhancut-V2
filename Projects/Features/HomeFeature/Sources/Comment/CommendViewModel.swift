//
//  CommendViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 2/24/26.
//

import UIKit
import RxSwift
import RxCocoa
import Domain

public final class CommentViewModel {
    
    public var onNeedRefresh: (() -> Void)?
    private let groupUsecase: GroupUsecaseProtocol
    private let postRelay: BehaviorRelay<Post>
    var currentPost: Post {
        postRelay.value
    }
    
    public struct Input {
        let sendTap: Observable<String>   // text
        let deleteTap: Observable<String> // commentId
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
        
        /*
         버튼탭
         - 댓글 추가 (Single)
         - 그룹 새로 로드 (Observable → Single)
         - 최신 post 찾아서 postRelay 갱신
         - 성공 여부를 Driver<Bool>로 반환
         */
        
        let sendResult = input.sendTap
            .flatMapLatest { [weak self] text -> Observable<Bool> in
                guard let self else { return .just(false) }
                
                return self.groupUsecase
                    .addComment(post: self.postRelay.value, text: text)   // Single<Void>
                    .asObservable()
                    .flatMapLatest { _ in
                        self.groupUsecase.loadAndFetchGroup()             // Observable<HCGroup>
                    }
                    .map { group in
                        if let updatedPost = group.postsByDate
                            .values
                            .flatMap({ $0 })
                            .first(where: { $0.postId == self.postRelay.value.postId }) {
                            
                            self.postRelay.accept(updatedPost)
                        }
                        return true
                    }
            }
            .asDriver(onErrorJustReturn: false)
        
        let deleteResult = input.deleteTap
            .flatMapLatest { [weak self] commentId -> Observable<Bool>  in
                guard let self else { return .just(false) }
                // 원본 저장(롤백용)
                let originalPost = self.postRelay.value
                
                // 1. 먼저 로컬 postRelay에서 제거
                var updatedPost = originalPost
                updatedPost.comments.removeValue(forKey: commentId)
                self.postRelay.accept(updatedPost)
                
                // 2. 서버 삭제 요청
                return self.groupUsecase
                    .deleteComment(post: self.postRelay.value,
                                   commentId: commentId)
                    .asObservable()
                // 3. 최신 그룹 다시 로드
                    .flatMapLatest { _ in
                        self.groupUsecase.loadAndFetchGroup()
                    }
                // 4. 최신 post로 동기화
                    .map { group in
                        if let refreshedPost = group.postsByDate
                            .values
                            .flatMap({ $0 })
                            .first(where: { $0.postId == originalPost.postId }) {
                            self.postRelay.accept(refreshedPost)
                        }
                        return true
                    }
                // 5. 실패 시 롤백
                    .catch { error in
                        self.postRelay.accept(originalPost) // 복구
                        return .just(false)
                    }
            }
            .asDriver(onErrorJustReturn: false)
        
        /*
         // 성공시만 reload
         filter { $0 } ==
         if success == true {
             emit()
         }
         */

        
        return Output(comments: comments,
                      sendResult: sendResult,
                      deleteResult: deleteResult)
    }
}
