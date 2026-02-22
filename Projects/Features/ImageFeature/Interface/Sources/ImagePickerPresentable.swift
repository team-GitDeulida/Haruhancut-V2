//
//  ImagePickerPresentable.swift
//  ImageFeatureInterface
//
//  Created by 김동현 on 2/21/26.
//

import UIKit
import Core

public protocol ImagePickerTrigger {
    var onImagePicked: ((UIImage) -> Void)? { get set }
}

public typealias ImagePickerViewModelType = ViewModelType & ImagePickerTrigger
public typealias ImagePickerPresentable = (vc: UIViewController, vm: any ImagePickerViewModelType)
