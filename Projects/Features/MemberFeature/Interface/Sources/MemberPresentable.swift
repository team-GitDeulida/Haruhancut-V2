//
//  Empty.swift
//  Member
//
//  Created by 김동현 on 
//

import UIKit
import Core
import Domain

public protocol MemberRouteTrigger {
    
}

public typealias MemberViewModelType = ViewModelType & MemberRouteTrigger
public typealias MemberPresentable = (vc: UIViewController, vm: any MemberViewModelType)
