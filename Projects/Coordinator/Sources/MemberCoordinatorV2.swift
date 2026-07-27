import MemberFeatureV2
import UIKit

/// MemberFeatureV2의 화면 이동을 담당합니다.
public final class MemberCoordinatorV2:
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
            MemberFeatureBuilder()
        var member =
            builder.makeMember()

        member.vm.onCellImageTapped = {
            [weak self] imageURL in
            guard let self else {
                return
            }
            let previewCoordinator =
                ImagePreviewCoordinator(
                    presentingViewController:
                        navigationController,
                    imageURL: imageURL
                )
            previewCoordinator
                .parentCoordinator = self
            childCoordinators.append(
                previewCoordinator
            )
            previewCoordinator.start()
        }

        navigationController
            .pushViewController(
                member.vc,
                animated: true
            )
    }
}
