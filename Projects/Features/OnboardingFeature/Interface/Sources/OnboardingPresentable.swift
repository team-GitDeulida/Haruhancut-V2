//
//  Empty.swift
//  Onboarding
//
//  Created by 김동현 on 
//

import Core
import UIKit

public protocol OnboardingRouteTrigger {
    
}

public typealias OnboardingViewModelType = ViewModelType & OnboardingRouteTrigger
public typealias OnboardingPresentable = (vc: UIViewController, vm: any OnboardingViewModelType)
