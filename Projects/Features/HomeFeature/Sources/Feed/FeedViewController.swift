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
import Core
import DSKit

final class FeedViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let homeViewModel: HomeViewModel
    private var customView = FeedView()
    private var output: HomeViewModel.Output?
    private let longPressRelay = PublishRelay<Post>()
    
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
        setupLongPress()
    }
    
    private func setupLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        customView.collectionView.addGestureRecognizer(longPress)
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
            }
            .disposed(by: disposeBag)
        
        // posts 상태에 따른 Empty UI 처리
        output.todayPosts
            .drive(with: self, onNext: { owner, posts in
                let isEmpty = posts.isEmpty
                owner.customView.emptyLabel.isHidden = !isEmpty
                owner.customView.collectionView.isHidden = isEmpty
            
                // 포스트가 비어있지 않으면서 && 내가 작성한 포스트가 하나라도 있다면
                if !posts.isEmpty && posts.contains(where: { $0.userId == owner.homeViewModel.userId }) {
                    // bubble
                    owner.customView.bubbleView.text = "오늘 사진 추가 완료"
                    owner.customView.bubbleView.alpha = 0.6
                } else {
                    self.customView.bubbleView.text = "사진 추가하기"
                }
            })
            .disposed(by: disposeBag)
        
        // refresh 종료 (성공)
        output.todayPosts
            .drive(with: self, onNext: { owner, _ in
                owner.customView.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        // refresh 종료 (에러)
        output.error
            .emit(with: self, onNext: { owner, _ in
                owner.customView.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        // 포스트 터치 바인딩
        customView.collectionView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(with: self, onNext: { owner, post in
                owner.homeViewModel.onImageTapped?(post)
            })
            .disposed(by: disposeBag)
        
        // 포스트 롱프레스 바인딩
        longPressRelay
            .subscribe(with: self, onNext: { owner, post in
                Logger.d("🔥 Long Press OK (Rx)")
                let alert = AlertFactory.makeAlert(title: "삭제 확인",
                                       message: "이 사진을 삭제하시겠습니까?",
                                       actions: [
                                        UIAlertAction(title: "삭제", style: .destructive) { _ in
                                            print("삭제")
                                        },
                                        UIAlertAction(title: "취소", style: .cancel)
                                       ])
                owner.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 카메라 터치 바인딩
        customView.cameraBtn.rx.tap
            .asDriver()
            .drive(with: self, onNext: { owner, _ in
                print("사진 추가하기")
                let alert = AlertFactory.makeAlert(title: nil,
                                                   message: nil,
                                                   preferredStyle: .actionSheet,
                                                   actions: [
                                                    UIAlertAction(title: "카메라로 찍기", style: .default) { _ in
                                                        print("카메라로 찍기")
                                                    },
                                                    UIAlertAction(title: "앨범에서 선택", style: .default) { _ in
                                                        print("앨범에서 선택")
                                                    }
                                                   ])
                owner.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 카메라 버튼 활성화 / 비활성화
        output.didTodayUpload
            .map { !$0 } // 오늘 올렸으면 버튼은 false
            .drive(customView.cameraBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // 카메라 버튼 투명도 조절
        output.didTodayUpload
            .map { $0 ? 0.3 : 1.0 }
            .asDriver(onErrorJustReturn: 1.0)
            .drive(customView.cameraBtn.rx.alpha)
            .disposed(by: disposeBag)
                
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Logger.d("👆 handleLongPress called, state = \(gesture.state.rawValue)")
        guard gesture.state == .began else { return }
        let location = gesture.location(in: customView.collectionView)
        guard
            let indexPath = customView.collectionView.indexPathForItem(at: location),
            let post = try? customView.collectionView.rx.model(at: indexPath) as Post,
            let uid = homeViewModel.userId,
            post.userId == uid
        else { return }
        
        longPressRelay.accept(post)
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
