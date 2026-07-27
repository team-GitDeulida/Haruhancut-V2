import MemberFeatureV2
import UIKit

final class SceneDelegate:
    UIResponder,
    UIWindowSceneDelegate
{
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session:
            UISceneSession,
        options connectionOptions:
            UIScene.ConnectionOptions
    ) {
        guard
            let windowScene =
                scene as? UIWindowScene
        else {
            return
        }

        let builder =
            MemberFeatureBuilder()
        var member =
            builder.makeMember()
        let navigationController =
            UINavigationController(
                rootViewController:
                    member.vc
            )
        member.vc.title = "Member V2"
        member.vm.onCellImageTapped = {
            [weak navigationController]
            imageURL in
            navigationController?.present(
                UIAlertController.notice(
                    title: "프로필 이미지",
                    message: imageURL
                ),
                animated: true
            )
        }

        let window = UIWindow(
            windowScene: windowScene
        )
        window.rootViewController =
            navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}

private extension UIAlertController {
    static func notice(
        title: String,
        message: String
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "확인",
                style: .default
            )
        )
        return alert
    }
}
