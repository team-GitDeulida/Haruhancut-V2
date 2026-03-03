//
//  NicknameSettingPresentable.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/3/26.
//

import Core
import UIKit

public protocol NicknameEditRouteTrigger {
    var onPopButtonTapped: (() -> Void)? { get set }
}

public typealias NicknameEditViewModelType = ViewModelType & NicknameEditRouteTrigger
public typealias NicknameEditPresentable = (vc: UIViewController, vm: any NicknameEditViewModelType)

