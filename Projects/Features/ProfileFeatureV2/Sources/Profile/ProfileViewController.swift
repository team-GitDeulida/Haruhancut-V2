import CollectionViewAdapter
import Core
import Domain
import DSKit
import Kingfisher
import ProfileFeatureV2Interface
import RxCocoa
import RxRelay
import RxSwift
import UIKit

final class ProfileViewController:
    UIViewController,
    RefreshableViewController
{
    private enum Constant {
        static let postSectionIdentifier =
            "profile-posts"
        static let columnCount = 3
        static let itemSpacing: CGFloat = 1
    }

    private struct ActiveImagePrefetch {
        let id: UUID
        let prefetcher: ImagePrefetcher
    }

    private let customView =
        ProfileView()
    private let viewModel:
        ProfileViewModel
    private let disposeBag =
        DisposeBag()
    private let reloadRelay =
        PublishRelay<Void>()
    private let imageTappedRelay =
        PublishRelay<Post>()
    private let nicknameEditTappedRelay =
        PublishRelay<Void>()
    private let birthdayEditTappedRelay =
        PublishRelay<Void>()
    private var imageURLsByPostID:
        [String: URL] = [:]
    private var activeImagePrefetches:
        [String: ActiveImagePrefetch] = [:]

    private lazy var adapter:
        CollectionViewAdapter = {
            let adapter =
                CollectionViewAdapter(
                    collectionView:
                        customView.collectionView
                )
            adapter.prefetchItems = {
                [weak self] items in
                self?.prefetchImages(
                    for: items
                )
            }
            adapter.cancelPrefetchingItems = {
                [weak self] items in
                self?.cancelImagePrefetching(
                    for: items
                )
            }
            return adapter
        }()

    private lazy var settingButton:
        UIBarButtonItem = {
            let item = UIBarButtonItem(
                image: UIImage(
                    systemName:
                        "gearshape.fill"
                ),
                style: .plain,
                target: nil,
                action: nil
            )
            item.tintColor = .mainWhite
            return item
        }()

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    deinit {
        activeImagePrefetches
            .values
            .forEach {
                $0.prefetcher.stop()
            }
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        bindViewModel()
    }

    func refresh() {
        reloadRelay.accept(())
    }

    private func configureNavigation() {
        navigationItem
            .rightBarButtonItem =
            settingButton
    }

    private func bindViewModel() {
        let profileImageTapped =
            Observable<Void>.create {
                [weak self] observer in
                self?.customView
                    .profileImageView
                    .onProfileTapped = {
                        observer.onNext(())
                    }
                return Disposables.create {
                    [weak self] in
                    self?.customView
                        .profileImageView
                        .onProfileTapped = nil
                }
            }

        let profileImageEditTapped =
            Observable<Void>.create {
                [weak self] observer in
                self?.customView
                    .profileImageView
                    .onCameraTapped = {
                        observer.onNext(())
                    }
                return Disposables.create {
                    [weak self] in
                    self?.customView
                        .profileImageView
                        .onCameraTapped = nil
                }
            }

        let viewWillAppear =
            rx.methodInvoked(
                #selector(
                    UIViewController
                        .viewWillAppear(_:)
                )
            )
            .map { _ in }

        customView.editButton.rx.tap
            .bind(with: self) {
                owner, _ in
                owner
                    .showProfileEditMenu()
            }
            .disposed(by: disposeBag)

        let input =
            ProfileViewModel.Input(
                profileImageTapped:
                    profileImageTapped,
                profileImageEditTapped:
                    profileImageEditTapped,
                nicknameEditTapped:
                    nicknameEditTappedRelay
                        .asObservable(),
                birthdayEditTapped:
                    birthdayEditTappedRelay
                        .asObservable(),
                settingTapped:
                    settingButton.rx.tap
                        .asObservable(),
                imageTapped:
                    imageTappedRelay
                        .asObservable(),
                reload:
                    reloadRelay
                        .asObservable(),
                viewWillAppear:
                    viewWillAppear
            )
        let output =
            viewModel.transform(
                input: input
            )

        output.user
            .drive(with: self) {
                owner, user in
                owner.customView
                    .nicknameLabel.text =
                    user.nickname
            }
            .disposed(by: disposeBag)

        output.user
            .map(\.profileImageURL)
            .drive(with: self) {
                owner, imageURL in
                guard
                    let imageURL,
                    let url = URL(
                        string: imageURL
                    )
                else {
                    return
                }
                owner.customView
                    .profileImageView
                    .setImage(with: url)
            }
            .disposed(by: disposeBag)

        output.myPosts
            .drive(with: self) {
                owner, posts in
                owner.render(posts)
            }
            .disposed(by: disposeBag)

        output.isLoading
            .distinctUntilChanged()
            .drive(with: self) {
                owner, isLoading in
                owner.updateLoadingState(
                    isLoading
                )
            }
            .disposed(by: disposeBag)
    }

    private func showProfileEditMenu() {
        let alert =
            UIAlertController(
                title:
                    LocalizationKey
                        .profileEditTitle
                        .localized,
                message: nil,
                preferredStyle:
                    .actionSheet
            )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .profileEditNickname
                        .localized,
                style: .default
            ) {
                [weak self] _ in
                self?
                    .nicknameEditTappedRelay
                    .accept(())
            }
        )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .profileEditBirthday
                        .localized,
                style: .default
            ) {
                [weak self] _ in
                self?
                    .birthdayEditTappedRelay
                    .accept(())
            }
        )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .commonCancel
                        .localized,
                style: .cancel
            )
        )

        if let popover =
            alert
                .popoverPresentationController
        {
            popover.sourceView =
                customView.editButton
            popover.sourceRect =
                customView.editButton
                    .bounds
        }
        present(
            alert,
            animated: true
        )
    }

    private func render(
        _ posts: [Post]
    ) {
        updateImageURLLookup(
            posts
        )
        let targetWidth =
            profilePostTargetWidth

        adapter.bind(
            SectionModels {
                LazySection(
                    identifier:
                        Constant
                            .postSectionIdentifier
                ) {
                    For(of: posts) {
                        post in
                        ProfilePostComponent(
                            post: post,
                            targetWidth:
                                targetWidth
                        )
                        .pressedEffect(scale: 0.98)
                        .onTouch {
                            [weak self] in
                            self?
                                .imageTappedRelay
                                .accept(post)
                        }
                    }
                }
                .withSectionLayout(
                    makeProfilePostGridLayout(
                        targetWidth:
                            targetWidth
                    )
                )
            },
            animatingDifferences: true
        )
    }

    private func makeProfilePostGridLayout(
        targetWidth: CGFloat
    ) -> CollectionSectionLayout {
        CollectionSectionLayout { _ in
            let item =
                NSCollectionLayoutItem(
                    layoutSize:
                        NSCollectionLayoutSize(
                            widthDimension:
                                .fractionalWidth(
                                    1 / CGFloat(
                                        Constant
                                            .columnCount
                                    )
                                ),
                            heightDimension:
                                .fractionalHeight(
                                    1
                                )
                        )
                )
            let group =
                NSCollectionLayoutGroup
                    .horizontal(
                        layoutSize:
                            NSCollectionLayoutSize(
                                widthDimension:
                                    .fractionalWidth(
                                        1
                                    ),
                                heightDimension:
                                    .absolute(
                                        targetWidth
                                            * 1.5
                                    )
                            ),
                        repeatingSubitem:
                            item,
                        count:
                            Constant
                                .columnCount
                    )
            group.interItemSpacing =
                .fixed(
                    Constant.itemSpacing
                )

            let section =
                NSCollectionLayoutSection(
                    group: group
                )
            section.interGroupSpacing =
                Constant.itemSpacing
            return section
        }
    }

    private var profilePostTargetWidth:
        CGFloat
    {
        let collectionWidth =
            customView.collectionView
                .bounds.width
        let availableWidth =
            collectionWidth > 1
            ? collectionWidth
            : UIScreen.main.bounds.width
        let totalSpacing =
            CGFloat(
                Constant.columnCount - 1
            ) * Constant.itemSpacing

        return max(
            (
                availableWidth
                    - totalSpacing
            ) / CGFloat(
                Constant.columnCount
            ),
            1
        )
    }

    private func updateImageURLLookup(
        _ posts: [Post]
    ) {
        imageURLsByPostID =
            posts.reduce(into: [:]) {
                result, post in
                guard
                    let url = URL(
                        string:
                            post.imageURL
                    )
                else {
                    return
                }
                result[post.postId] =
                    url
            }

        let currentPostIDs =
            Set(
                imageURLsByPostID.keys
            )
        let removedPostIDs =
            activeImagePrefetches
                .keys
                .filter {
                    !currentPostIDs
                        .contains($0)
                }
        cancelImagePrefetching(
            forPostIDs:
                removedPostIDs
        )
    }

    private func prefetchImages(
        for items:
            [CollectionViewPrefetchItem]
    ) {
        for postID in profilePostIDs(
            from: items
        ) {
            guard
                activeImagePrefetches[
                    postID
                ] == nil,
                let imageURL =
                    imageURLsByPostID[
                        postID
                    ]
            else {
                continue
            }

            let requestID = UUID()
            let prefetcher =
                ImagePrefetcher(
                    urls: [imageURL],
                    options:
                        ProfilePostImageRequest
                            .options(
                                targetWidth:
                                    profilePostTargetWidth
                            ),
                    completionHandler: {
                        [weak self] _, _, _ in
                        guard
                            self?
                                .activeImagePrefetches[
                                    postID
                                ]?.id
                                == requestID
                        else {
                            return
                        }
                        self?
                            .activeImagePrefetches[
                                postID
                            ] = nil
                    }
                )
            activeImagePrefetches[
                postID
            ] = ActiveImagePrefetch(
                id: requestID,
                prefetcher: prefetcher
            )
            prefetcher.start()
        }
    }

    private func cancelImagePrefetching(
        for items:
            [CollectionViewPrefetchItem]
    ) {
        cancelImagePrefetching(
            forPostIDs:
                profilePostIDs(
                    from: items
                )
        )
    }

    private func cancelImagePrefetching(
        forPostIDs postIDs: [String]
    ) {
        for postID in postIDs {
            activeImagePrefetches
                .removeValue(
                    forKey: postID
                )?
                .prefetcher
                .stop()
        }
    }

    private func profilePostIDs(
        from items:
            [CollectionViewPrefetchItem]
    ) -> [String] {
        items.compactMap { item in
            guard
                item.sectionIdentifier ==
                    AnyHashable(
                        Constant
                            .postSectionIdentifier
                    ),
                let postID =
                    item.itemIdentifier
                        .base as? String
            else {
                return nil
            }
            return postID
        }
    }

    private func updateLoadingState(
        _ isLoading: Bool
    ) {
        setPopGestureEnabled(
            !isLoading
        )
        if isLoading {
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
        }
    }

    private func showLoadingIndicator() {
        guard
            customView.loadingView == nil
        else {
            return
        }

        let rootView =
            navigationController?.view
            ?? customView
        let loadingView = UIView()
        loadingView.backgroundColor =
            UIColor.black
                .withAlphaComponent(0.3)
        loadingView.isUserInteractionEnabled =
            true
        loadingView
            .translatesAutoresizingMaskIntoConstraints =
            false

        let indicator =
            UIActivityIndicatorView(
                style: .large
            )
        indicator
            .translatesAutoresizingMaskIntoConstraints =
            false
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        rootView.addSubview(loadingView)
        customView.loadingView =
            loadingView

        NSLayoutConstraint.activate([
            loadingView.topAnchor
                .constraint(
                    equalTo:
                        rootView.topAnchor
                ),
            loadingView.bottomAnchor
                .constraint(
                    equalTo:
                        rootView.bottomAnchor
                ),
            loadingView.leadingAnchor
                .constraint(
                    equalTo:
                        rootView.leadingAnchor
                ),
            loadingView.trailingAnchor
                .constraint(
                    equalTo:
                        rootView.trailingAnchor
                ),
            indicator.centerXAnchor
                .constraint(
                    equalTo:
                        loadingView
                            .centerXAnchor
                ),
            indicator.centerYAnchor
                .constraint(
                    equalTo:
                        loadingView
                            .centerYAnchor
                ),
        ])
    }

    private func hideLoadingIndicator() {
        customView.loadingView?
            .removeFromSuperview()
        customView.loadingView = nil
    }

    private func setPopGestureEnabled(
        _ isEnabled: Bool
    ) {
        navigationController?
            .interactivePopGestureRecognizer?
            .isEnabled = isEnabled
    }
}
