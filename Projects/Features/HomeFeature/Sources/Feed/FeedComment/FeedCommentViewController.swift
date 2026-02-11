//
//  FeedCommentViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 2/11/26.
//

import UIKit
import RxSwift
import Domain
import RxCocoa

final class FeedCommentViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let customView: FeedCommentView
    private let feedDetailViewModel: FeedDetailViewModel
    
    init(feedDetailViewModel: FeedDetailViewModel) {
        self.feedDetailViewModel = feedDetailViewModel
        self.customView = FeedCommentView(post: feedDetailViewModel.currentPost)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindViewModel() {
        // 댓글 전송
        let sendTap = customView.chattingView.sendButton.rx.tap // ControlEvent<Void>
            .map { [weak self] in
                self?.customView.chattingView.text ?? ""
            } // Observable<String>
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Observable<String>
            .filter { !$0.isEmpty }
            .share() // 이벤트를 한 번만 실행하고 여러 구독자에게 공유
        
        // 댓글 삭제
        let deleteTap = customView.tableView.rx
            .itemDeleted
            .withLatestFrom(customView.tableView.rx.modelSelected(Comment.self)) { indexPath, comment in
                return comment.commentId
            }
        
        
        let input = FeedDetailViewModel.Input(sendTap: sendTap, deleteTap: deleteTap)
        let output = feedDetailViewModel.transform(input: input)
        
        // 채팅 로드
        output.comments
            .drive(customView.tableView.rx.items(cellIdentifier: CommentCell.reuseIdentifier,
                                                 cellType: CommentCell.self)) { _, comment, cell in
                cell.configure(comment: comment)
                cell.selectionStyle = .none
            }
            .disposed(by: disposeBag)
        
        // 전송 결과 처리
        output.sendResult
            .drive(with: self) { owner, success in
                if success {
                    owner.customView.chattingView.clearInput()
                } else {
                    // AlertManager.showError(on: owner, message: "댓글 작성 실패")
                }
            }
            .disposed(by: disposeBag)
        
        // 삭제 결과 처리
        output.deleteResult
            .drive(with: self) { owner, success in
                if !success {
                    // AlertManager.showError(on: owner, message: "댓글 삭제 실패")
                }
            }
            .disposed(by: disposeBag)

        
        
        // 댓글 작성
        /*
        customView.chattingView.sendButton.rx.tap
            .map { [weak self] in
                self?.customView.chattingView.text ?? ""
            }
            .filter { !$0.isEmpty }
            .subscribe(with: self, onNext: { owner, text in
                print("전송: \(text)")
                owner.customView.chattingView.clearInput()
            })
            .disposed(by: disposeBag)
         
         customView.chattingView.sendButton.rx.tap
             .map { [weak self] in
                 self?.customView.chattingView.text ?? ""
             }
             .filter { !$0.isEmpty }
             .flatMapLatest { [weak self] text -> Driver<Bool> in
                 guard let self else { return .empty() }
                 // return self.viewModel.addComment(text: text)
                 return .just(true)
             }
             .drive(with: self) { owner, success in
                 if success {
                     owner.customView.chattingView.clearInput()
                 } else {
                     AlertManager.showError(on: owner, message: "댓글 작성 실패")
                 }
             }
             .disposed(by: disposeBag)
         */
        

        
            
        
        // 댓글 삭제(swipe)
        /*
        customView.tableView.rx.modelSelected(CommentCell.self)
            .flatMapLatest { [weak self] comment -> Driver<Bool> in
                guard let self = self else { return .empty() }
                // 뷰모델에서 삭제 로직
                return .just(true)
            }
            .asDriver(onErrorJustReturn: false)
            .drive()
            .disposed(by: disposeBag)
         */
        
    }
}

// MARK: - BottomSheet
extension FeedCommentViewController {
    func configureSheet() {
        modalPresentationStyle = .pageSheet
        guard let sheet = sheetPresentationController else { return }
        
        if #available(iOS 16.0, *) {
            
            let percent60 = UISheetPresentationController.Detent.custom(identifier: .init("percent60")) { context in
                return context.maximumDetentValue * 0.6
            }
            
            let percent90 = UISheetPresentationController.Detent.custom(identifier: .init("percent90")) { context in
                return context.maximumDetentValue * 0.9
            }
            
            sheet.detents = [percent60, percent90]
        } else {
            sheet.detents = [.medium(), .large()]
        }
        
        /// 바텀시트 상단에 손잡이(Grabber) 표시 여부
        sheet.prefersGrabberVisible = true
        
        /// 시트의 상단 모서리를 24pt 둥글게
        sheet.preferredCornerRadius = 24
        
        modalPresentationStyle = .pageSheet
    }
}
