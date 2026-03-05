//
//  OnboardingViewModel.swift
//  OnboardingFeature
//
//  Created by 김동현 on 3/5/26.
//

import Foundation
import OnboardingFeatureInterface

final class OnboardingViewModel: OnboardingViewModelType {
    
    // MARK: - Coordinator Trigger
    var onEndButtonTapped: (() -> Void)?
    
    struct Input {}
    struct Output {}
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
