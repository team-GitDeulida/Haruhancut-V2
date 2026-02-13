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
import RxCocoa

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
        

        let input = FeedDetailViewModel.DetailInput(imageTapped: customView.imageView.rx.tap.asObservable(),
                                                    commentButtonTapped: customView.commentButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)
        
        // 게시물 업데이트 감지 후 댓글 수 반영을 한다
        output.commentCount
            .drive(with: self) { owner, count in
                owner.customView.commentButton.setCount(count)
            }
            .disposed(by: disposeBag)
    }
}

extension Reactive where Base: UIView {
    /*
     [이 확장이 없다면 해야하는 방식]
     var imageTapped: Observable<Void> {
         let tapGesture = UITapGestureRecognizer()
         customView.imageView.isUserInteractionEnabled = true
         customView.imageView.addGestureRecognizer(tapGesture)
         return tapGesture.rx.event
             .map { _ in () }
     }
     */
    var tap: ControlEvent<Void> {
        let gesture = UITapGestureRecognizer()
        base.addGestureRecognizer(gesture)
        base.isUserInteractionEnabled = true
        let source = gesture.rx.event.map { _ in () }
        return ControlEvent(events: source)
    }
}
