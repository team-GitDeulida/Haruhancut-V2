//
//  CommentViewController.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import RxSwift
import Domain
import RxCocoa
import Core
import DSKit

final class CommentViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let customView: CommentView
    private let commentViewModel: CommentViewModel
    private let deleteRelay = PublishRelay<String>()
    var onDismiss: (() -> Void)?
    private var didNotifyDismiss = false

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard !didNotifyDismiss,
              isBeingDismissed || isMovingFromParent else { return }

        didNotifyDismiss = true
        onDismiss?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindViewModel() {
        customView.tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        let sendTap = customView.chattingView.sendButton.rx.tap
            .map { [weak self] in
                self?.customView.chattingView.text ?? ""
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .share()

        let deleteTap = deleteRelay.asObservable()

        let input = CommentViewModel.Input(sendTap: sendTap, deleteTap: deleteTap)
        let output = commentViewModel.transform(input: input)

        output.comments
            .drive(customView.tableView.rx.items(cellIdentifier: CommentCell.reuseIdentifier,
                                                 cellType: CommentCell.self)) { _, comment, cell in
                cell.configure(comment: comment)
                cell.selectionStyle = .none
            }
            .disposed(by: disposeBag)

        output.sendResult
            .drive(with: self) { owner, success in
                if success {
                    owner.customView.chattingView.clearInput()
                }
            }
            .disposed(by: disposeBag)

        output.deleteResult
            .drive(with: self) { owner, success in
                if success {
                } else {
                }
            }
            .disposed(by: disposeBag)
    }
}

extension CommentViewController {
    func configureSheet() {
        modalPresentationStyle = .pageSheet
        guard let sheet = sheetPresentationController else { return }

        if #available(iOS 16.0, *) {
            let percent60 = UISheetPresentationController.Detent.custom(identifier: .init("percent60")) { context in
                context.maximumDetentValue * 0.6
            }

            let percent90 = UISheetPresentationController.Detent.custom(identifier: .init("percent90")) { context in
                context.maximumDetentValue * 0.9
            }

            sheet.detents = [percent60, percent90]
        } else {
            sheet.detents = [.medium(), .large()]
        }

        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24
    }
}

extension CommentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive,
                                         title: LocalizationKey.commonDelete.localized) { [weak self] _, _, completion in
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
