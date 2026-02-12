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
import Data
import HomeFeatureInterface

public final class FeedDetailViewModel: FeedDetailViewModelType {
    public var onCommentTapped: (() -> Void)?
    
    @Dependency private var userSession: UserSession
//    private var currentUserId: String? {
//        return userSession.sessionUser?.userId
//    }
//    private var currentGroupId: String? {
//        return userSession.sessionUser?.groupId
//    }
    public var currentPost: Post {
        postRelay.value
    }
    private let groupUsecase: GroupUsecaseProtocol
    private let disposeBag = DisposeBag()
    private let postRelay: BehaviorRelay<Post>

    
    public struct Input {
        let sendTap: Observable<String>
        let deleteTap: Observable<String>
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
            .asObservable()   // Driver에서 잠깐 빠져나오기
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

        
//        let sendResult = input.sendTap
//            .do(onNext: { text in
//                print("🟢 sendTap 들어옴:", text)
//            })
//            .asDriver(onErrorJustReturn: "")
//            .flatMapLatest { [weak self] text -> Driver<Bool> in
//                guard let self else { return Driver.just(false) }
//                print("🟢 addComment 시작")
//                return self.groupUsecase
//                    .addComment(post: self.currentPost, text: text) // Single<Void>
//                    .do(onSuccess: {
//                        print("🟢 addComment 성공")
//                    }, onError: { error in
//                        print("🔴 addComment 실패:", error)
//                    })
//                    .flatMap { _ in
//                        self.groupUsecase
//                            .loadAndFetchGroup()       // Observable<HCGroup>
//                            .do(onNext: { group in
//                                print("🟢 group 로드됨, post 개수:",
//                                      group.postsByDate.values.flatMap { $0 }.count)
//                            })
//                            .skip(1)                   // 캐시 무시
//                            .take(1)                   // 1번만
//                            .asSingle()                // Single<HCGroup>
//                    }
//                    .map { group in
//                        if let updatedPost = group.postsByDate
//                            .values
//                            .flatMap({ $0 })
//                            .first(where: { $0.postId == self.currentPost.postId }) {
//
//                            self.postRelay.accept(updatedPost)
//                        }
//                        return true
//                    }
//                    .asDriver(onErrorJustReturn: false)
//            }

        
//        let sendResult = input.sendTap
//            .asDriver(onErrorJustReturn: "")
//            .flatMapLatest { [weak self] text in
//                guard let self else { return Driver.just(false) }
//
//                return self.groupUsecase
//                    .addComment(post: self.currentPost, text: text)
//                    .map { true }
//                    .asDriver(onErrorJustReturn: false)
//            }
        
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
        
        return Output(comments: comments, sendResult: sendResult, deleteResult: .just(false))
    }

}
