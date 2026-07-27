import Core
import UIKit

public protocol SettingRouteTrigger {
    var onLogoutTapped:
        (() -> Void)? { get set }
}

public typealias SettingViewModelType =
    ViewModelType & SettingRouteTrigger
public typealias SettingPresentable = (
    vc: UIViewController,
    vm: any SettingViewModelType
)
