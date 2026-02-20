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
                    .addComment(post: self.currentPost, text: text)   // Single<Void>
                    .asObservable()
                    .flatMapLatest { _ in
                        self.groupUsecase.loadAndFetchGroup()          // Observable<HCGroup>
                    }
                    .map { group in
                        if let updatedPost = group.postsByDate
                            .values
                            .flatMap({ $0 })
                            .first(where: { $0.postId == self.currentPost.postId }) {

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
                let originalPost = self.currentPost
                
                // 1. 먼저 로컬 postRelay에서 제거
                var updatedPost = originalPost
                updatedPost.comments.removeValue(forKey: commentId)
                self.postRelay.accept(updatedPost)
                
                // 2. 서버 삭제 요청
                return self.groupUsecase
                    .deleteComment(post: self.currentPost,
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

        
        return Output(comments: comments,
                      sendResult: sendResult,
                      deleteResult: deleteResult)
    }

}

extension FeedDetailViewModel {
    public struct DetailInput {
        let imageTapped: Observable<Void>
        let commentButtonTapped: Observable<Void>
    }
    
    public struct DetailOutput {
        let commentCount: Driver<Int>
    }
    
    public func transform(input: DetailInput) -> DetailOutput {
        
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
        
        return DetailOutput(commentCount: commentCount)
    }
}






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




/*
let sendResult = input.sendTap
    .flatMapLatest { [weak self] text -> Observable<Bool> in
        guard let self else { return .just(false) }

        // 0 원본 저장
        let originalPost = self.currentPost

        // 1 Optimistic UI: 임시 댓글 생성
        let tempComment = Comment(
            commentId: UUID().uuidString,
            userId: self.userSession.userId ?? "",
            nickname: "나", // 필요하면 세션 닉네임
            text: text,
            createdAt: Date()
        )

        var optimisticPost = originalPost
        optimisticPost.comments[tempComment.commentId] = tempComment
        self.postRelay.accept(optimisticPost)

        // 2 서버 요청
        return self.groupUsecase
            .addComment(post: originalPost, text: text)
            .asObservable()
            .flatMapLatest { _ in
                self.groupUsecase.loadAndFetchGroup()
            }
            .map { group in
                if let refreshedPost = group.postsByDate
                    .values
                    .flatMap({ $0 })
                    .first(where: { $0.postId == originalPost.postId }) {

                    self.postRelay.accept(refreshedPost)
                }
                return true
            }
            .catch { error in
                // 3 실패 시 롤백
                self.postRelay.accept(originalPost)
                return .just(false)
            }
    }
    .asDriver(onErrorJustReturn: false)
 */



/*
 [애니메이션 버벅임]
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
             .addComment(post: self.currentPost, text: text)   // Single<Void>
             .asObservable()
             .flatMapLatest { _ in
                 self.groupUsecase.loadAndFetchGroup()          // Observable<HCGroup>
             }
             .map { group in
                 if let updatedPost = group.postsByDate
                     .values
                     .flatMap({ $0 })
                     .first(where: { $0.postId == self.currentPost.postId }) {

                     self.postRelay.accept(updatedPost)
                 }
                 return true
             }
     }
     .asDriver(onErrorJustReturn: false)
let deleteResult = input.deleteTap
    .flatMapLatest { [weak self] commentId -> Observable<Bool>  in
        guard let self else { return .just(false) }
        return self.groupUsecase
            .deleteComment(post: self.currentPost,
                           commentId: commentId)
            .asObservable()
            .flatMapLatest { _ in
                self.groupUsecase.loadAndFetchGroup()
            }
            .map { group in
                if let updatedPost = group.postsByDate
                    .values
                    .flatMap({ $0 })
                    .first(where: { $0.postId == self.currentPost.postId }) {
                    
                    self.postRelay.accept(updatedPost)
                }
                return true
            }
            .catchAndReturn(false)
    }
    .asDriver(onErrorJustReturn: false)
 */
