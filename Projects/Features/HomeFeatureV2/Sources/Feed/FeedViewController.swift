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
import ReactorKit
import DSKit
import Domain
import CollectionViewAdapter

final class FeedViewController: UIViewController, View {

    var disposeBag = DisposeBag()
    private let customView = FeedView()
    private let isReadOnly:
        Bool

    private lazy var collectionViewAdapter = CollectionViewAdapter(
        collectionView: customView.collectionView
    )
    private let refreshControl = UIRefreshControl()

    private let imageTappedRelay = PublishRelay<Post>()
    private let longPressedRelay = PublishRelay<Post>()
    private var currentComponents: [FeedComponent] = []
    private var didSkipInitialAppear = false

    init(
        reactor: FeedReactor,
        isReadOnly:
            Bool = false
    ) {
        self.isReadOnly =
            isReadOnly
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
        setupRefreshControl()
        customView.cameraBtn
            .isHidden =
            isReadOnly
        customView.bubbleView
            .isHidden =
            isReadOnly
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
        let shouldAnimate = !currentComponents.isEmpty
        currentComponents = components

        collectionViewAdapter.bind(
            SectionModels {
                LazySection(identifier: "feed") {
                    For(of: components) { component in
                        self.makeInteractiveComponent(
                            component
                        )
                    }
                }
                .withSectionLayout(
                    .grid(
                        columns: 2,
                        estimatedRowHeight: 240,
                        interItemSpacing: 20,
                        lineSpacing: 20,
                        contentInsets:
                            NSDirectionalEdgeInsets(
                                top: 20,
                                leading: 16,
                                bottom: 0,
                                trailing: 16
                            )
                    )
                )
            },
            animatingDifferences: shouldAnimate
        )

        let hasContent = !components.isEmpty
        customView.emptyLabel.text =
            isReadOnly
            ? LocalizationKey
                .adminPreviewEmpty
                .localized
            : LocalizationKey
                .homeDescription
                .localized
        customView.emptyLabel.isHidden = hasContent
        customView.bubbleView.text = hasContent
            ? LocalizationKey.homeFeedBubbleDoneToday.localized
            : LocalizationKey.homeFeedBubbleAddPhoto.localized

        let canAddPhoto =
            !hasContent ||
            ProcessInfo.processInfo.arguments.contains("-UITest")
        customView.cameraBtn.isEnabled =
            !isReadOnly && canAddPhoto
        customView.cameraBtn.alpha =
            canAddPhoto ? 1.0 : 0.3
    }

    private func makeInteractiveComponent(
        _ component: FeedComponent
    ) -> AnyComponent {
        let interactiveComponent = component
            .pressedEffect()
            .onTouch { [weak self] in
                self?.imageTappedRelay.accept(
                    component.post
                )
            }

        guard !isReadOnly else {
            return AnyComponent(
                interactiveComponent
            )
        }

        return AnyComponent(
            interactiveComponent
                .onLongPress(
                    minimumDuration: 0.4
                ) { [weak self] in
                    self?.longPressedRelay.accept(
                        component.post
                    )
                }
        )
    }

    private func setupRefreshControl() {
        refreshControl.tintColor = .mainWhite
        refreshControl.attributedTitle = NSAttributedString(
            string: "새로고침 중...",
            attributes: [
                .foregroundColor: UIColor.mainWhite,
            ]
        )
        refreshControl.addTarget(
            self,
            action: #selector(didRequestRefresh),
            for: .valueChanged
        )
        customView.collectionView.refreshControl =
            refreshControl
    }

    @objc
    private func didRequestRefresh() {
        reactor?.action.onNext(.refresh)
    }

    private func updateRefreshingState(isLoading: Bool) {
        guard
            !isLoading,
            refreshControl.isRefreshing
        else {
            return
        }

        refreshControl.endRefreshing()
        let topOffset = -customView.collectionView.adjustedContentInset.top
        customView.collectionView.setContentOffset(.init(x: 0, y: topOffset), animated: false)
    }
}

//#Preview {
//    let vc = FeedViewController(reactor: HomeReactor())
//    UINavigationController(rootViewController: vc)
//
//}
