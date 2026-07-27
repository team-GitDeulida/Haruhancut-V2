import Core
import UIKit

public protocol BirthdayEditRouteTrigger {
    var onPopButtonTapped:
        (() -> Void)? { get set }
}

public typealias BirthdayEditViewModelType =
    ViewModelType & BirthdayEditRouteTrigger
public typealias BirthdayEditPresentable = (
    vc: UIViewController,
    vm: any BirthdayEditViewModelType
)
