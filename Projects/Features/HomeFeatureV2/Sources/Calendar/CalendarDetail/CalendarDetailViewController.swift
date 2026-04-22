//
//  CalendarDetailViewController.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import Foundation
import UIKit
import RxSwift
import Domain
import RxCocoa
import Core
import DSKit

final class CalendarDetailViewController: UIViewController, RefreshableViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel: CalendarDetailViewModel
    private let customView: CalendarDetailView
    private let currentRelay = BehaviorRelay<Int>(value: 0)
    private let reloadRelay = PublishRelay<Void>()
    
    init(viewModel: CalendarDetailViewModel) {
        self.viewModel = viewModel
        self.customView = CalendarDetailView(posts: viewModel.posts,
                                             selectedDate: viewModel.selectedDate.toDateKey())
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
        setDelegate()
        bindViewModel()
    }

    func refresh() {
        reloadRelay.accept(())
    }
    
    private func setDelegate() {
        customView.collectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        let viewDidAppear = rx
            .methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in }
        let reload = Observable.merge(viewDidAppear, reloadRelay.asObservable())

        let commentTapped = customView.commentButton.rx.tap
            .withUnretained(self)
            .compactMap { owner,  _ -> Post? in
                let index = owner.customView.currentIndex
                guard owner.viewModel.posts.indices.contains(index) else {
                    return nil
                }
                return owner.viewModel.posts[index]
            }
        
        let input = CalendarDetailViewModel.Input(
            imageTapped: customView.collectionView.rx.modelSelected(Post.self).asObservable(),
            commentButtonTapped: commentTapped,
            currentIndex: currentRelay.asObservable(),
            reload: reload)
        let output = viewModel.transform(input: input)
        
        customView.closeButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { owner, _ in
                owner.dismiss(animated: true)
            }).disposed(by: disposeBag)
        
        output.posts
            .drive(customView.collectionView.rx
                .items(cellIdentifier: CalendarDetailCell.reuseIdentifier,
                       cellType: CalendarDetailCell.self)) { _, post, cell in
                cell.setKFImage(url: post.imageURL)
            }.disposed(by: disposeBag)
        
        output.commentCount
            .drive(with: self, onNext: { owner, count in
                owner.customView.commentButton.setCount(count)
            }).disposed(by: disposeBag)
    }
}

extension CalendarDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let witdth = collectionView.bounds.width - 40
        return CGSize(width: witdth, height: witdth)
    }
}

extension CalendarDetailViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = customView.collectionView.frame.width
        let offsetX = customView.collectionView.contentOffset.x
        let index = Int(round(offsetX / pageWidth))
        customView.currentIndex = index
        currentRelay.accept(index)
    }
}
