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
import Core

final class CommentViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let customView: CommentView
    private let commentViewModel: CommentViewModel
    private let deleteRelay = PublishRelay<String>()
    
    init(commentViewModel: CommentViewModel) {
        self.customView = CommentView(post: commentViewModel.currentPost)
        self.commentViewModel = commentViewModel
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
        
        customView.tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        // 댓글 전송
        let sendTap = customView.chattingView.sendButton.rx.tap // ControlEvent<Void>
            .map { [weak self] in
                self?.customView.chattingView.text ?? ""
            } // Observable<String>
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Observable<String>
            .filter { !$0.isEmpty }
            .share() // 이벤트를 한 번만 실행하고 여러 구독자에게 공유
        
        // 댓글 삭제
        let deleteTap = deleteRelay.asObservable()

        let input = CommentViewModel.Input(sendTap: sendTap, deleteTap: deleteTap)
        let output = commentViewModel.transform(input: input)
        
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
                    
                    // Notification
                    Logger.d("Notification: 댓글 추가 이벤트 방출")
                    owner.sendNoti(action: .add)
                } else {
                    // AlertManager.showError(on: owner, message: "댓글 작성 실패")
                }
            }
            .disposed(by: disposeBag)
        
        // 삭제 결과 처리
        output.deleteResult
            .drive(with: self) { owner, success in
                if success {
                    // Notification
                    Logger.d("Notification: 댓글 삭제 이벤트 방출")
                    owner.sendNoti(action: .delete)
                } else {
                    // AlertManager.showError(on: owner, message: "댓글 삭제 실패")
                }
            }
            .disposed(by: disposeBag)
        
    }
}

// MARK: - BottomSheet
extension CommentViewController {
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
    }
}

// MARK: - Swipe
extension CommentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive,
                                         title: "삭제") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            
            guard let comment = try? self.customView.tableView.rx.model(at: indexPath) as Comment else {
                completion(false)
                return
            }
            
            self.deleteRelay.accept(comment.commentId)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }
}

