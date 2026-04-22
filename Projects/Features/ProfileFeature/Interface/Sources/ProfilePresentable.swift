//
//  Empty.swift
//  Profile
//
//  Created by 김동현 on 
//

import UIKit
import Core
import Domain

public protocol ProfileRouteTrigger {
    var onProfileImageTapped: ((String) -> Void)? { get set }
    // var onProfileImageEditButtonTapped: (() -> Void)? { get set }
    // (Coordinator가 받을 completion) -> Void
    // var onProfileImageEditButtonTapped: (((UIImage) -> Void) -> Void)?
    var onProfileImageEditButtonTapped: ((@escaping (UIImage) -> Void) -> Void)? { get set }
    var onSettingButtonTapped: (() -> Void)? { get set }
    var onNicknameEditButtonTapped: (() -> Void)? { get set }
    var onImageTapped: ((Post) -> Void)? { get set }
}

public typealias ProfileViewModelType = ViewModelType & ProfileRouteTrigger
public typealias ProfileViewControllerType = UIViewController

public typealias ProfilePresentable = (vc: ProfileViewControllerType, vm: any ProfileViewModelType)
