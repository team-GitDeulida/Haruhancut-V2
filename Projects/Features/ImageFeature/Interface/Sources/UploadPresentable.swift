//
//  Empty.swift
//  Image
//
//  Created by 김동현 on 
//

import UIKit
import Core

public protocol UploadTrigger {
    var onUploadCompleted: (() -> Void)? { get set }
}

public typealias UploadViewModelType = ViewModelType & UploadTrigger
public typealias UploadViewControllerType = UIViewController & PopableViewController
public typealias UploadPresentable = (vc: UploadViewControllerType, vm: any UploadViewModelType)

