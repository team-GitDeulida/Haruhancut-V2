//
//  Empty.swift
//  Profile
//
//  Created by 김동현 on 
//

import UIKit
import Core

public protocol ProfileRouteTrigger {
    
}

public typealias ProfileViewModelType = ViewModelType & ProfileRouteTrigger
public typealias ProfileViewControllerType = UIViewController & PopableViewController

public typealias ProfilePresentable = (vc: ProfileViewControllerType, vm: any ProfileViewModelType)
