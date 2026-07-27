import Core
import Domain
import UIKit

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
    var onImageTapped:
        ((Post) -> Void)? { get set }
}

public typealias ProfileViewModelType =
    ViewModelType & ProfileRouteTrigger
public typealias ProfileViewControllerType =
    UIViewController
public typealias ProfilePresentable = (
    vc: ProfileViewControllerType,
    vm: any ProfileViewModelType
)
