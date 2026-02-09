//
//  FeedViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 2/9/26.
//

import UIKit
import Domain
import RxSwift
import RxCocoa

final class FeedViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let homeViewModel: HomeViewModel
    private var customView = FeedView()
    
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
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
    
    // MARK: - Bindings
    private func bindViewModel() {
        /// 포스트 터치 바인딩
        customView.collectionView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(onNext: { [weak self] post in
                guard let self = self else { return }
            })
            .disposed(by: disposeBag)
    }
}
