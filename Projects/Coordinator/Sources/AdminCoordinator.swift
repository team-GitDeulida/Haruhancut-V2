import AdminFeature
import Domain
import HomeFeatureV2
import HomeFeatureV2Interface
import UIKit

/// 관리자 그룹 목록과 선택한 그룹의 읽기 전용 Home 이동을 담당합니다.
public final class AdminCoordinator:
    Coordinator,
    HomeRouteTrigger
{
    public var parentCoordinator:
        Coordinator?
    public var childCoordinators:
        [Coordinator] = []
    public var onImageTapped:
        ((Post) -> Void)?
    public var onMemberTapped:
        (() -> Void)?
    public var onProfileTapped:
        (() -> Void)?
    public var onCameraTapped:
        ((CameraSource) -> Void)?
    public var onCalendarImageTapped:
        (([Post], Date) -> Void)?

    private let navigationController:
        UINavigationController
    private var selectedGroupID:
        String?

    public init(
        navigationController:
            UINavigationController
    ) {
        self.navigationController =
            navigationController
        configureRoutes()
    }

    public func start() {
        let builder =
            AdminFeatureBuilder()
        var admin =
            builder.makeAdmin()

        admin.vm.onGroupTapped = {
            [weak self] group in
            self?.showGroupHome(
                groupID:
                    group.groupId
            )
        }

        navigationController
            .pushViewController(
                admin.vc,
                animated: true
            )
    }

    private func showGroupHome(
        groupID: String
    ) {
        selectedGroupID =
            groupID
        let home =
            HomeFeatureBuilder()
                .makeHome(
                    mode:
                        .adminPreview(
                            groupID:
                                groupID
                        ),
                    routeTrigger: self
                )
        navigationController
            .pushViewController(
                home,
                animated: true
            )
    }

    private func configureRoutes() {
        onImageTapped = {
            [weak self] post in
            self?.showFeedDetail(
                post
            )
        }
        onCalendarImageTapped = {
            [weak self] posts,
            selectedDate in
            self?.showCalendarDetail(
                posts: posts,
                selectedDate:
                    selectedDate
            )
        }
    }

    private func showFeedDetail(
        _ post: Post
    ) {
        guard
            let selectedGroupID
        else {
            return
        }

        let builder =
            FeedDetailBuilder()
        var detail =
            builder.makeFeed(
                post: post,
                mode:
                    .adminPreview(
                        groupID:
                            selectedGroupID
                    )
            )
        let viewController =
            detail.vc
        detail.vm
            .onImagePreviewTapped = {
                [weak self, weak viewController]
                imageURL in
                guard
                    let viewController
                else {
                    return
                }
                self?.presentImagePreview(
                    imageURL,
                    from:
                        viewController
                )
            }

        navigationController
            .pushViewController(
                viewController,
                animated: true
            )
    }

    private func showCalendarDetail(
        posts: [Post],
        selectedDate: Date
    ) {
        guard
            let selectedGroupID
        else {
            return
        }

        let builder =
            CalendarDetailBuilder()
        var detail =
            builder
                .makeCalendarDetail(
                    posts: posts,
                    selectedDate:
                        selectedDate,
                    mode:
                        .adminPreview(
                            groupID:
                                selectedGroupID
                        )
                )
        let viewController =
            detail.vc
        detail.vm
            .onImagePreviewTapped = {
                [weak self, weak viewController]
                imageURL in
                guard
                    let viewController
                else {
                    return
                }
                self?.presentImagePreview(
                    imageURL,
                    from:
                        viewController
                )
            }
        viewController
            .modalPresentationStyle =
            .fullScreen
        navigationController.present(
            viewController,
            animated: true
        )
    }

    private func presentImagePreview(
        _ imageURL: String,
        from viewController:
            UIViewController
    ) {
        let coordinator =
            ImagePreviewCoordinator(
                presentingViewController:
                    viewController,
                imageURL: imageURL
            )
        coordinator.parentCoordinator =
            self
        childCoordinators.append(
            coordinator
        )
        coordinator.start()
    }
}
