//
//  HomePresentable.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/19/26.
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
    var onMemberTapped: (() -> Void)? { get set }
    var onProfileTapped: (() -> Void)? { get set }
    var onCameraTapped: ((CameraSource) -> Void)? { get set }
    var onCalendarImageTapped: (([Post], Date) -> Void)? { get set }
}

public typealias HomeReducerType = HomeRouteTrigger
public typealias HomePresentable = (vc: UIViewController, reducer: any HomeReducerType)
