//
//  ProfileFeatureBuilder.swift
//  ProfileFeature
//
//  Created by 김동현 on 2/9/26.
//

import ProfileFeatureInterface
import UIKit
import Core
import Domain

public protocol ProfileFeatureBuildable {
    func makeProfile() -> ProfilePresentable
    func makeSetting() -> SettingPresentable
}

public final class ProfileFeatureBuilder {
    public init() {}
}

extension ProfileFeatureBuilder: ProfileFeatureBuildable {
    public func makeProfile() -> ProfilePresentable {
        @Dependency var userSession: UserSession
        @Dependency var authUsecase: AuthUsecaseProtocol
        @Dependency var gropUsecase: GroupUsecaseProtocol
        let vm = ProfileViewModel(userSession: userSession,
                                  authUsecase: authUsecase,
                                  groupUsecase: gropUsecase)
        let vc = ProfileViewController(viewModel: vm)
        return (vc, vm)
    }
    
    public func makeSetting() -> SettingPresentable {
        @Dependency var authUsecase: AuthUsecaseProtocol
        let vm = SettingViewModel(authUsecase: authUsecase)
        let vc = SettingViewController(settingViewModel: vm)
        return (vc, vm)
    }
}
