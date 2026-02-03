//
//  GroupPresentable.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import Core

public protocol GroupRouteTrigger {
    var onGroupMakeOrJoinSuccess: (() -> Void)? { get set }
}

public typealias GroupViewModelType = ViewModelType & GroupRouteTrigger

public typealias GroupPresentable = (vc: UIViewController, vm: any GroupViewModelType)
