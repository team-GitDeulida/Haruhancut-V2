//
//  FeedDetailViewController.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import RxSwift
import HomeFeatureV2Interface
import Domain
import RxRelay
import Core
import RxCocoa
import Kingfisher
import DSKit

final class FeedDetailViewController: UIViewController, RefreshableViewController {

    private let disposeBag = DisposeBag()
    private let viewModel: FeedDetailViewModel
    private let customView: FeedDetailView
    private let reloadRelay = PublishRelay<Void>()
    
    init(viewModel: FeedDetailViewModel) {
        self.viewModel = viewModel
        self.customView = FeedDetailView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    func refresh() {
        reloadRelay.accept(())
    }
    
    private func bindViewModel() {
        let viewDidAppear = rx
            .methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in }
        let reload = Observable.merge(viewDidAppear, reloadRelay.asObservable())

        let input = FeedDetailViewModel.Input(
            imageTapped: customView.imageView.rx.tap.asObservable(),
            commentButtonTapped: customView.commentButton.rx.tap.asObservable(),
            reload: reload)
        let output = viewModel.transform(input: input)
        
        output.post
            .drive(with: self, onNext: { owner, post in
                owner.customView.configure(post: post)
            })
            .disposed(by: disposeBag)
        
        output.commentCount
            .drive(with: self) { owner, count in
                owner.customView.commentButton.setCount(count)
            }
            .disposed(by: disposeBag)
    }
}
