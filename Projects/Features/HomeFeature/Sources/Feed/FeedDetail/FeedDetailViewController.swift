//
//  FeedDetailViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 2/10/26.
//

import UIKit
import RxSwift
import HomeFeatureInterface
import Domain
import RxRelay
import Core

final class FeedDetailViewController: UIViewController, PopableViewController {
    
    var onPop: (() -> Void)?
    private let disposeBag = DisposeBag()
    private let viewModel: FeedDetailViewModel
    private let customView: FeedDetailView
    
    // 이미지 탭 이벤트(UIKit → Rx 브릿지)
    private let imageTapRelay = PublishRelay<UIImage>()
    
    init(viewModel: FeedDetailViewModel) {
        self.viewModel = viewModel
        self.customView = FeedDetailView(post: viewModel.currentPost)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            onPop?()
        }
    }

    
    // MARK: - Bindings
    private func bindViewModel() {
        customView.commentButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { owner, _ in
                owner.viewModel.onCommentTapped?()
            })
            .disposed(by: disposeBag)
    }
}
