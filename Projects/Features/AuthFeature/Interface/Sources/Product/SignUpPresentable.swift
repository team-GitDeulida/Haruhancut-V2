//
//  SignUpPresentable.swift
//  AuthFeature
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import Core

public protocol SignUpRouteTrigger {
    var onSignUpSuccess: (() -> Void)? { get set }
}

public typealias SignUpViewModelType = ViewModelType & SignUpRouteTrigger

public typealias SignUpPresentable = (vc: UIViewController, vm: any SignUpViewModelType)
