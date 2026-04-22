//
//  FeedViewController.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/20/26.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import CarbonListKit
import ReactorKit
import DSKit
import Domain

final class FeedViewController: UIViewController, View {

    var disposeBag = DisposeBag()
    
    private let customView = FeedView()
    private lazy var adapter = ListAdapter(collectionView: customView.collectionView)
    private let imageTappedRelay = PublishRelay<Post>()
    private let longPressedRelay = PublishRelay<Post>()
    private var currentComponents: [FeedComponent] = []
    private var didSkipInitialAppear = false
    
    init(reactor: FeedReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLongPress()
        reactor?.action.onNext(.viewDidLoad)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard didSkipInitialAppear else {
            didSkipInitialAppear = true
            return
        }

        reactor?.action.onNext(.viewDidAppear)
    }
    
    var cameraButtonTapped: Driver<Void> {
        customView.cameraBtn.rx.tap.asDriver()
    }

    var imageTapped: Driver<Post> {
        imageTappedRelay.asDriver(onErrorDriveWith: .empty())
    }

    var longPressed: Driver<Post> {
        longPressedRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    func bind(reactor: FeedReactor) {
        reactor.state
            .map(\.isLoading)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, isLoading in
                owner.updateRefreshingState(isLoading: isLoading)
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.components)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, components in
                owner.render(components: components)
            }
            .disposed(by: disposeBag)
    }

    private func render(components: [FeedComponent]) {
        currentComponents = components
        adapter.apply(
            List {
                Section(id: "section-1") {
                    for component in components {
                        Cell(id: component.content.postId, component: component)
                            .onSelect { [weak self] _ in
                                self?.imageTappedRelay.accept(component.content)
                            }
                    }
                }
                .layout(.grid(columns: 2, itemSpacing: 20, lineSpacing: 20))
                .contentInsets(.init(top: 20, leading: 16, bottom: 0, trailing: 16))
            }
            .pullToRefresh(
                style: .custom(.init(
                    title: "새로고침",
                    titleColor: .secondaryLabel,
                    titleFont: .systemFont(ofSize: 14, weight: .medium),
                    indicator: .image(
                        image: UIImage(systemName: "arrow.clockwise")!,
                        tintColor: .systemOrange,
                        contentMode: .scaleAspectFit,
                        size: .init(width: 22, height: 22),
                        rotatesWhileRefreshing: true,
                        rotationDuration: 0.8
                    )
                ))
            ) { [weak self] in
                self?.reactor?.action.onNext(.refresh)
                try? await Task.sleep(for: .seconds(1))
            },
            updateStrategy: .animated
        )

        let hasContent = !components.isEmpty
        customView.emptyLabel.isHidden = hasContent
        customView.bubbleView.text = hasContent
            ? LocalizationKey.homeFeedBubbleDoneToday.localized
            : LocalizationKey.homeFeedBubbleAddPhoto.localized
        customView.cameraBtn.isEnabled = !hasContent
        customView.cameraBtn.alpha = hasContent ? 0.3 : 1.0
    }

    private func setupLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        customView.collectionView.addGestureRecognizer(longPress)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let location = gesture.location(in: customView.collectionView)
        guard
            let indexPath = customView.collectionView.indexPathForItem(at: location),
            currentComponents.indices.contains(indexPath.item)
        else { return }

        let post = currentComponents[indexPath.item].content
        longPressedRelay.accept(post)
    }

    private func updateRefreshingState(isLoading: Bool) {
        guard !isLoading, customView.collectionView.refreshControl?.isRefreshing == true else { return }

        customView.collectionView.refreshControl?.endRefreshing()
        let topOffset = -customView.collectionView.adjustedContentInset.top
        customView.collectionView.setContentOffset(.init(x: 0, y: topOffset), animated: false)
    }
}

//#Preview {
//    let vc = FeedViewController(reactor: HomeReactor())
//    UINavigationController(rootViewController: vc)
//    
//}
