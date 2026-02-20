//
//  Empty.swift
//  Image
//
//  Created by 김동현 on 
//

import UIKit
import Core

public protocol CameraTrigger {
    var onCameraButtonTapped: ((UIImage) -> Void)? { get set }
}

public typealias CameraViewModelType = ViewModelType & CameraTrigger
public typealias CameraViewControllerType = UIViewController & PopableViewController
public typealias CameraPresentable = (vc: CameraViewControllerType, vm: any CameraViewModelType)

