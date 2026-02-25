//
//  ViewControllerType.swift
//  Core
//
//  Created by 김동현 on 2/9/26.
//

import Foundation

public protocol PopableViewController: AnyObject {
    var onPop: (() -> Void)? { get set }
}

public protocol DismissableViewController: AnyObject {
    var onDismiss: (() -> Void)? { get set }
}

public protocol RefreshableViewController: AnyObject {
    func refresh()
}
