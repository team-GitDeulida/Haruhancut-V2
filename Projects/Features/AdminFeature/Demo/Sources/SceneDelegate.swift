import AdminFeature
import AdminFeatureInterface
import UIKit

final class SceneDelegate:
    UIResponder,
    UIWindowSceneDelegate
{
    var window: UIWindow?
    private var admin:
        AdminPresentable?

    func scene(
        _ scene: UIScene,
        willConnectTo
        session: UISceneSession,
        options
        connectionOptions:
            UIScene
                .ConnectionOptions
    ) {
        guard
            let windowScene =
                scene as? UIWindowScene
        else {
            return
        }

        let builder =
            AdminFeatureBuilder()
        var admin =
            builder.makeAdmin(
                adminUsecase:
                    DemoAdminUsecase()
            )
        let navigationController =
            UINavigationController(
                rootViewController:
                    admin.vc
            )

        admin.vm.onGroupTapped = {
            [weak navigationController]
            group in
            let alert =
                UIAlertController(
                    title:
                        group.groupName,
                    message:
                        "선택한 그룹의 읽기 전용 Home 화면으로 이동합니다.",
                    preferredStyle:
                        .alert
                )
            alert.addAction(
                UIAlertAction(
                    title: "확인",
                    style: .default
                )
            )
            navigationController?
                .present(
                    alert,
                    animated: true
                )
        }

        self.admin = admin
        let window =
            UIWindow(
                windowScene:
                    windowScene
            )
        window.rootViewController =
            navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}
