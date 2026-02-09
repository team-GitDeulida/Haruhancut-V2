//
//  ProfileFeatureBuilder.swift
//  ProfileFeature
//
//  Created by 김동현 on 2/9/26.
//

import ProfileFeatureInterface
import UIKit

public protocol ProfileFeatureBuildable {
    func makeProfile() -> ProfilePresentable
}

public final class ProfileFeatureBuilder {
    public init() {}
}

extension ProfileFeatureBuilder: ProfileFeatureBuildable {
    public func makeProfile() -> ProfilePresentable {
        let vm = ProfileViewModel()
        let vc = ProfileViewController(viewModel: vm)
        return (vc, vm)
    }
}
