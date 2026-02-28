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
    var onSettingButtonTapped: (() -> Void)? { get set }
    var onImageTapped: ((Post) -> Void)? { get set }
}

public typealias ProfileViewModelType = ViewModelType & ProfileRouteTrigger
public typealias ProfileViewControllerType = UIViewController & PopableViewController

public typealias ProfilePresentable = (vc: ProfileViewControllerType, vm: any ProfileViewModelType)
