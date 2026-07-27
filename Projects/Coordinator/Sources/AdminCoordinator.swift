import AdminFeature
import HomeFeatureV2
import HomeFeatureV2Interface
import UIKit

/// 관리자 그룹 목록과 선택한 그룹의 읽기 전용 Home 이동을 담당합니다.
public final class AdminCoordinator:
    Coordinator
{
    public var parentCoordinator:
        Coordinator?
    public var childCoordinators:
        [Coordinator] = []

    private let navigationController:
        UINavigationController

    public init(
        navigationController:
            UINavigationController
    ) {
        self.navigationController =
            navigationController
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
        let home =
            HomeFeatureBuilder()
                .makeHome(
                    mode:
                        .adminPreview(
                            groupID:
                                groupID
                        ),
                    routeTrigger: nil
                )
        navigationController
            .pushViewController(
                home,
                animated: true
            )
    }
}
