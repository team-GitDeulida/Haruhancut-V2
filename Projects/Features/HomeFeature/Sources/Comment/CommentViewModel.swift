//
//  CommentViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 2/24/26.
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
        // TODO: - reload를 usecase 내부 처리 고려
        let sendResult = input.sendTap
            .withUnretained(self)
            .concatMap { owner, text -> Observable<Bool> in
                return owner.groupUsecase
                    .addComment(post: owner.postRelay.value, text: text)   // Single<Void>
                    .asObservable()
                    .withUnretained(self)
                    .flatMapLatest { owner, _ in
                        owner.groupUsecase.loadAndFetchGroup()             // Observable<HCGroup>
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
            .concatMap { owner, commentId -> Observable<Bool>  in
                // 원본 저장(롤백용)
                let originalPost = owner.postRelay.value
                
                // 1. 먼저 로컬 postRelay에서 제거
                var updatedPost = originalPost
                updatedPost.comments.removeValue(forKey: commentId)
                owner.postRelay.accept(updatedPost)
                
                // 2. 서버 삭제 요청
                return owner.groupUsecase
                    .deleteComment(post: originalPost,
                                   commentId: commentId)
                    .asObservable()
                // 3. 최신 그룹 다시 로드
                    .withUnretained(self)
                    .flatMapLatest { owner, _ in
                        owner.groupUsecase.loadAndFetchGroup()
                            .takeLast(1) // 삭제 시에는 서버 값만 받아오겠다
                    }
                // 4. 최신 post로 동기화
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
                // 5. 실패 시 롤백
                    .catch { error in
                        owner.postRelay.accept(originalPost) // 복구
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
