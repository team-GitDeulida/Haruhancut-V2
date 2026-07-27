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
    private let isReadOnly:
        Bool

    init(
        viewModel: FeedDetailViewModel,
        isReadOnly:
            Bool = false
    ) {
        self.viewModel = viewModel
        self.customView = FeedDetailView()
        self.isReadOnly =
            isReadOnly
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
        customView.commentButton
            .isHidden =
            isReadOnly
        customView.commentButton
            .isEnabled =
            !isReadOnly
        bindViewModel()
    }

    func refresh() {
        reloadRelay.accept(())
    }

    private func bindViewModel() {
        let reload = Observable.merge(
            Observable<Void>.just(()),
            reloadRelay.asObservable()
        )

        let commentButtonTapped:
            Observable<Void> =
            isReadOnly
            ? .never()
            : customView
                .commentButton
                .rx
                .tap
                .asObservable()
        let input = FeedDetailViewModel.Input(
            imageTapped: customView.imageView.rx.tap.asObservable(),
            commentButtonTapped:
                commentButtonTapped,
            reload: reload)
        let output = viewModel.transform(input: input)

        output.imageURL
            .drive(with: self, onNext: { owner, imageURL in
                owner.customView.configure(imageURL: imageURL)
            })
            .disposed(by: disposeBag)

        output.commentCount
            .drive(with: self) { owner, count in
                owner.customView.commentButton.setCount(count)
            }
            .disposed(by: disposeBag)
    }
}
