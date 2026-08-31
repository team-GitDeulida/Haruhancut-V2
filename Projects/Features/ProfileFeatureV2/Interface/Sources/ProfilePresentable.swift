import Core
import Domain
import UIKit

public struct ProfilePostSelection {
    public let post: Post
    public let previewImage: UIImage?

    public init(
        post: Post,
        previewImage: UIImage?
    ) {
        self.post = post
        self.previewImage = previewImage
    }
}

public protocol ProfileRouteTrigger {
    var onProfileImageTapped:
        ((String) -> Void)? { get set }
    var onProfileImageEditButtonTapped:
        ((@escaping (UIImage) -> Void) -> Void)? {
            get set
        }
    var onSettingButtonTapped:
        (() -> Void)? { get set }
    var onNicknameEditButtonTapped:
        (() -> Void)? { get set }
    var onBirthdayEditButtonTapped:
        (() -> Void)? { get set }
    var onImageTapped:
        ((ProfilePostSelection) -> Void)? { get set }
}

public typealias ProfileViewModelType =
    ViewModelType & ProfileRouteTrigger
public typealias ProfileViewControllerType =
    UIViewController
public typealias ProfilePresentable = (
    vc: ProfileViewControllerType,
    vm: any ProfileViewModelType
)
