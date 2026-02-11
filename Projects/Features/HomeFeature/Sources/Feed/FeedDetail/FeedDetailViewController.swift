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
    private let homeViewModel: any HomeViewModelType
    private let customView: FeedDetailView
    
    // 이미지 탭 이벤트(UIKit → Rx 브릿지)
    private let imageTapRelay = PublishRelay<UIImage>()
    
    init(homeViewModel: any HomeViewModelType, post: Post) {
        self.homeViewModel = homeViewModel
        self.customView = FeedDetailView(post: post)
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
        view.backgroundColor = .systemBackground
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            onPop?()
        }
    }
}
