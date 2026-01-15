//
//  SignInPresentable.swift
//  AuthFeatureInterface
//
//  Created by 김동현 on 1/15/26.
//

import UIKit
import Core

/// 화면 전환 로직을 View / ViewModel 밖으로 분리하기 위한 트리거 -> Coordinator
public protocol SignInRouteTrigger {
    var onSignInSuccess: (() -> Void)? { get set }
}

/// ViewModel Protocol
public typealias SignInViewModelType = ViewModelType & SignInRouteTrigger

// MARK: - Product
public typealias SignInPresentable = (vc: UIViewController, vm: any SignInViewModelType)
