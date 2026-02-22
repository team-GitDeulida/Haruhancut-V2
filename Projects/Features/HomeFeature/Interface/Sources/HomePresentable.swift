//
//  HomePresentable.swift
//  Home
//
//  Created by 김동현 on 
//

import UIKit
import Core
import Domain

public enum CameraSource {
    case camera
    case album
}

public protocol HomeRouteTrigger {
    var onImageTapped: ((Post) -> Void)? { get set }
    var onLogoutTapped: (() -> Void)? { get set }
    var onProfileTapped: (() -> Void)? { get set }
    var onCameraTapped: ((CameraSource) -> Void)? { get set }
}

public typealias HomeViewModelType = ViewModelType & HomeRouteTrigger

public typealias HomePresentable = (vc: UIViewController, vm: any HomeViewModelType)
