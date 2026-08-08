import Domain
import ProfileFeatureV2
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
            ProfileFeatureBuilder()
        var profile =
            builder.makeProfile()
        let navigationController =
            UINavigationController(
                rootViewController:
                    profile.vc
            )
        profile.vc.title =
            "Profile V2"
        profile.vc.navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                title: "이미지 실험",
                primaryAction: UIAction {
                    [weak navigationController] _ in
                    navigationController?.pushViewController(
                        ProfileImageCacheDemoViewController(),
                        animated: true
                    )
                }
            )

        profile.vm
            .onProfileImageTapped = {
                [weak navigationController]
                imageURL in
                Self.showNotice(
                    on:
                        navigationController,
                    title: "프로필 이미지",
                    message: imageURL
                )
            }

        profile.vm
            .onProfileImageEditButtonTapped = {
                [weak navigationController]
                completion in
                let image =
                    UIGraphicsImageRenderer(
                        size: CGSize(
                            width: 300,
                            height: 300
                        )
                    )
                    .image { context in
                        UIColor.systemYellow
                            .setFill()
                        context.fill(
                            CGRect(
                                x: 0,
                                y: 0,
                                width: 300,
                                height: 300
                            )
                        )
                    }
                completion(image)
                Self.showNotice(
                    on:
                        navigationController,
                    title: "프로필 수정",
                    message:
                        "Demo 이미지로 변경했습니다."
                )
            }

        profile.vm
            .onNicknameEditButtonTapped = {
                [weak navigationController]
                in
                var nicknameEdit =
                    builder
                        .makeNicknameEdit()
                nicknameEdit.vm
                    .onPopButtonTapped = {
                        [weak navigationController]
                        in
                        navigationController?
                            .popViewController(
                                animated: true
                            )
                    }
                navigationController?
                    .pushViewController(
                        nicknameEdit.vc,
                        animated: true
                    )
            }

        profile.vm
            .onBirthdayEditButtonTapped = {
                [weak navigationController]
                in
                var birthdayEdit =
                    builder
                        .makeBirthdayEdit()
                birthdayEdit.vm
                    .onPopButtonTapped = {
                        [weak navigationController]
                        in
                        navigationController?
                            .popViewController(
                                animated: true
                            )
                    }
                navigationController?
                    .pushViewController(
                        birthdayEdit.vc,
                        animated: true
                    )
            }

        profile.vm
            .onSettingButtonTapped = {
                [weak navigationController]
                in
                var setting =
                    builder.makeSetting()
                setting.vm.onLogoutTapped = {
                    [weak navigationController]
                    in
                    Self.showNotice(
                        on:
                            navigationController,
                        title: "로그아웃",
                        message:
                            "Demo 세션을 로그아웃했습니다."
                    )
                }
                navigationController?
                    .pushViewController(
                        setting.vc,
                        animated: true
                    )
            }

        profile.vm.onImageTapped = {
            [weak navigationController]
            selection in
            Self.showNotice(
                on: navigationController,
                title: "게시물 선택",
                message: selection.post.postId
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

    private static func showNotice(
        on navigationController:
            UINavigationController?,
        title: String,
        message: String
    ) {
        navigationController?.present(
            UIAlertController.notice(
                title: title,
                message: message
            ),
            animated: true
        )
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
