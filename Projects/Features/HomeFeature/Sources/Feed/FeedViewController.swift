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
    private var output: HomeViewModel.Output?
    
    // HomeVC가 구독할 refresh 이벤트
    var refreshTriggered: Observable<Void> {
        customView.refreshControl.rx
            .controlEvent(.valueChanged)
            .asObservable()
    }
    
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
    }
    
    // MARK: - Bindings
    func setOutput(_ output: HomeViewModel.Output) {
        customView.collectionView.rx.setDelegate(self)
                .disposed(by: disposeBag)
        self.output = output
        bindIfPossible()
    }
    
    private func bindIfPossible() {
        guard let output else { return }
        
        // posts → CollectionView 셀 렌더링
        output.todayPosts
            .drive(customView.collectionView.rx.items(
                cellIdentifier: FeedCell.reuseIdentifier,
                cellType: FeedCell.self
            )) { _, post, cell in
                cell.configure(post: post)
                print(post)
            }
            .disposed(by: disposeBag)
        
        // posts 상태에 따른 Empty UI 처리
        output.todayPosts
            .drive(onNext: { [weak self] posts in
                let isEmpty = posts.isEmpty
                self?.customView.emptyLabel.isHidden = !isEmpty
                self?.customView.collectionView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)
        
        // refresh 종료 (성공)
        output.todayPosts
            .drive(onNext: { [weak self] _ in
                self?.customView.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        // refresh 종료 (에러)
        output.error
            .emit(onNext: { [weak self] _ in
                self?.customView.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
    }
}

extension FeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
            let width = collectionView.bounds.width
            guard width > 0 else { return .zero }

            let spacing: CGFloat = 16 * 3 // left + right + interItem
            let itemWidth = (width - spacing) / 2

            return CGSize(width: itemWidth, height: itemWidth)
        }
}



//    private func bindViewModel() {
//        /// 포스트 터치 바인딩
//        customView.collectionView.rx.modelSelected(Post.self)
//            .asDriver()
//            .drive(onNext: { [weak self] post in
//                guard let self = self else { return }
//            })
//            .disposed(by: disposeBag)
//    }
