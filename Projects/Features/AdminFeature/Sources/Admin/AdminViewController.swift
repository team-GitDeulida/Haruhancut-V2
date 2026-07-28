import CollectionViewAdapter
import Domain
import DSKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit

final class AdminViewController:
    UIViewController
{
    private enum Constant {
        static let sectionIdentifier =
            "admin-groups"
        static let estimatedRowHeight:
            CGFloat = 150
    }

    private let customView =
        AdminView()
    private let viewModel:
        AdminViewModel
    private let disposeBag =
        DisposeBag()
    private let reloadRelay =
        PublishRelay<Void>()
    private let groupTappedRelay =
        PublishRelay<
            AdminGroupSummary
        >()
    private let sortOptionRelay =
        BehaviorRelay<
            AdminGroupSortOption
        >(
            value: .latestPost
        )
    private let refreshControl =
        UIRefreshControl()
    private var currentGroups:
        [AdminGroupSummary] = []

    private lazy var adapter =
        CollectionViewAdapter(
            collectionView:
                customView.collectionView
        )

    private lazy var latestPostFormatter:
        DateFormatter = {
            let formatter =
                DateFormatter()
            formatter.locale =
                .autoupdatingCurrent
            formatter.timeZone =
                .autoupdatingCurrent
            formatter.dateStyle =
                .medium
            formatter.timeStyle =
                .short
            return formatter
        }()

    init(
        viewModel:
            AdminViewModel
    ) {
        self.viewModel =
            viewModel
        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    @available(*, unavailable)
    required init?(
        coder: NSCoder
    ) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureRefreshControl()
        bindViewModel()
    }

    private func configureNavigation() {
        title =
            LocalizationKey
                .adminTitle
                .localized
        navigationController?
            .navigationBar
            .tintColor =
            .mainWhite

        let sortButton =
            UIBarButtonItem(
                image:
                    UIImage(
                        systemName:
                            "arrow.up.arrow.down"
                    ),
                menu:
                    makeSortMenu()
            )
        sortButton.tintColor =
            .mainWhite
        sortButton
            .accessibilityLabel =
            LocalizationKey
                .adminSort
                .localized
        navigationItem
            .rightBarButtonItem =
            sortButton
    }

    private func configureRefreshControl() {
        refreshControl.tintColor =
            .mainWhite
        refreshControl.addTarget(
            self,
            action:
                #selector(
                    didRequestReload
                ),
            for: .valueChanged
        )
        customView.collectionView
            .refreshControl =
            refreshControl
    }

    private func bindViewModel() {
        let output =
            viewModel.transform(
                input:
                    AdminViewModel.Input(
                        reload:
                            reloadRelay
                                .asObservable(),
                        groupTapped:
                            groupTappedRelay
                                .asObservable(),
                        sortOption:
                            sortOptionRelay
                                .asObservable()
                    )
            )

        output.screenState
            .drive(with: self) {
                owner, state in
                owner.apply(
                    state
                )
            }
            .disposed(by: disposeBag)

        output.loadFailed
            .emit(with: self) {
                owner, _ in
                owner.showLoadFailure()
            }
            .disposed(by: disposeBag)
    }

    private func apply(
        _ state: AdminScreenState
    ) {
        render(state.groups)
        currentGroups =
            state.groups

        let showsFullScreenLoading =
            state.isLoading
                && state.groups.isEmpty
                && !refreshControl
                    .isRefreshing
        if showsFullScreenLoading {
            customView
                .activityIndicator
                .startAnimating()
        } else {
            customView
                .activityIndicator
                .stopAnimating()
        }

        if !state.isLoading,
           refreshControl.isRefreshing
        {
            refreshControl
                .endRefreshing()
        }

        customView.emptyLabel
            .isHidden =
            state.isLoading
                || !state.groups.isEmpty
    }

    private func render(
        _ groups:
            [AdminGroupSummary]
    ) {
        let components =
            groups.map {
                group in
                AdminGroupComponent(
                    group: group,
                    metricsText:
                        metricsText(
                            for: group
                        ),
                    latestPostText:
                        latestPostText(
                            for: group
                        )
                )
            }

        adapter.bind(
            SectionModels {
                LazySection(
                    identifier:
                        Constant
                            .sectionIdentifier
                ) {
                    For(
                        of: components
                    ) {
                        component in
                        component
                            .pressedEffect(scale: 0.98)
                            .onTouch {
                                [weak self] in
                                self?
                                    .groupTappedRelay
                                    .accept(
                                        component
                                            .group
                                    )
                            }
                    }
                }
                .withSectionLayout(
                    .verticalList(
                        estimatedRowHeight:
                            Constant
                                .estimatedRowHeight,
                        spacing: 12,
                        contentInsets:
                            .init(
                                top: 20,
                                leading: 20,
                                bottom: 24,
                                trailing: 20
                            )
                    )
                )
            },
            animatingDifferences:
                !currentGroups.isEmpty
        )
    }

    private func metricsText(
        for group:
            AdminGroupSummary
    ) -> String {
        [
            String(
                format:
                    LocalizationKey
                        .adminMemberCount
                        .localized,
                group.memberCount
            ),
            String(
                format:
                    LocalizationKey
                        .adminPostCount
                        .localized,
                group.postCount
            ),
            String(
                format:
                    LocalizationKey
                        .adminPhotoCount
                        .localized,
                group.photoCount
            ),
        ].joined(separator: " · ")
    }

    private func latestPostText(
        for group:
            AdminGroupSummary
    ) -> String {
        guard
            let latestPostDate =
                group.latestPostDate
        else {
            return LocalizationKey
                .adminNoPost
                .localized
        }

        return String(
            format:
                LocalizationKey
                    .adminLatestPost
                    .localized,
            latestPostFormatter
                .string(
                    from:
                        latestPostDate
                )
        )
    }

    private func showLoadFailure() {
        guard
            presentedViewController
                == nil
        else {
            return
        }

        let alert =
            UIAlertController(
                title:
                    LocalizationKey
                        .adminLoadFailureTitle
                        .localized,
                message:
                    LocalizationKey
                        .adminLoadFailureMessage
                        .localized,
                preferredStyle:
                    .alert
            )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .commonDone
                        .localized,
                style: .default
            )
        )
        present(
            alert,
            animated: true
        )
    }

    private func makeSortMenu()
        -> UIMenu
    {
        let selectedOption =
            sortOptionRelay.value
        let actions =
            AdminGroupSortOption
                .allCases
                .map {
                    [weak self] option in
                    UIAction(
                        title:
                            option
                                .localizedTitle,
                        image:
                            option.image,
                        state:
                            selectedOption
                                == option
                            ? .on
                            : .off
                    ) {
                        _ in
                        self?
                            .selectSortOption(
                                option
                            )
                    }
                }

        return UIMenu(
            title:
                LocalizationKey
                    .adminSort
                    .localized,
            options:
                .singleSelection,
            children:
                actions
        )
    }

    private func selectSortOption(
        _ option:
            AdminGroupSortOption
    ) {
        guard sortOptionRelay.value
                != option
        else {
            return
        }

        sortOptionRelay.accept(
            option
        )
        navigationItem
            .rightBarButtonItem?
            .menu =
            makeSortMenu()
    }

    @objc
    private func didRequestReload() {
        reloadRelay.accept(())
    }
}

private extension AdminGroupSortOption {
    var localizedTitle: String {
        switch self {
        case .latestPost:
            return LocalizationKey
                .adminSortLatestPost
                .localized
        case .groupCreatedAt:
            return LocalizationKey
                .adminSortGroupCreatedAt
                .localized
        case .groupName:
            return LocalizationKey
                .adminSortGroupName
                .localized
        case .memberCount:
            return LocalizationKey
                .adminSortMemberCount
                .localized
        case .postCount:
            return LocalizationKey
                .adminSortPostCount
                .localized
        case .photoCount:
            return LocalizationKey
                .adminSortPhotoCount
                .localized
        }
    }

    var image: UIImage? {
        switch self {
        case .latestPost:
            return UIImage(
                systemName:
                    "clock"
            )
        case .groupCreatedAt:
            return UIImage(
                systemName:
                    "calendar.badge.plus"
            )
        case .groupName:
            return UIImage(
                systemName:
                    "textformat"
            )
        case .memberCount:
            return UIImage(
                systemName:
                    "person.2"
            )
        case .postCount:
            return UIImage(
                systemName:
                    "doc.text"
            )
        case .photoCount:
            return UIImage(
                systemName:
                    "photo"
            )
        }
    }
}
