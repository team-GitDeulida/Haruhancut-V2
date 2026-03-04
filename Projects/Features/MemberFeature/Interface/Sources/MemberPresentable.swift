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
    var onCellImageTapped: ((String) -> Void)? { get set }
}

public typealias MemberViewModelType = ViewModelType & MemberRouteTrigger
public typealias MemberPresentable = (vc: UIViewController, vm: any MemberViewModelType)
