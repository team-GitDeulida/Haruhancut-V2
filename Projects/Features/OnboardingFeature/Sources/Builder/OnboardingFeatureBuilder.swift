//
//  OnboardingFeatureBuilder.swift
//  OnboardingFeature
//
//  Created by 김동현 on 3/5/26.
//

import Foundation
import OnboardingFeatureInterface

public protocol OnboardingFeatureBuildable {
    func makeOnboarding() -> OnboardingPresentable
}

public final class OnboardingFeatureBuilder {
    public init() {}
}

extension OnboardingFeatureBuilder: OnboardingFeatureBuildable {
    public func makeOnboarding() -> OnboardingPresentable {
        let vm = OnboardingViewModel()
        let vc = OnboardingViewController(viewModel: vm)
        return (vc, vm)
    }
}
