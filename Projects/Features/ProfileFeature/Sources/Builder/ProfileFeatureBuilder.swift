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
    func makeProfile(onPop: (() -> Void)?) -> ProfilePresentable
    func makeSetting() -> SettingPresentable
    func makeNicknameEdit() -> NicknameEditPresentable
}

public final class ProfileFeatureBuilder {
    public init() {}
}

extension ProfileFeatureBuilder: ProfileFeatureBuildable {
    public func makeProfile(onPop: (() -> Void)? = nil) -> ProfilePresentable {
        @Dependency var userSession: UserSession
        @Dependency var authUsecase: AuthUsecaseProtocol
        @Dependency var gropUsecase: GroupUsecaseProtocol
        let vm = ProfileViewModel(userSession: userSession,
                                  authUsecase: authUsecase,
                                  groupUsecase: gropUsecase)
        let vc = ProfileViewController(viewModel: vm)
        vc.onPop = onPop
        return (vc, vm)
    }
    
    public func makeSetting() -> SettingPresentable {
        @Dependency var authUsecase: AuthUsecaseProtocol
        let vm = SettingViewModel(authUsecase: authUsecase)
        let vc = SettingViewController(settingViewModel: vm)
        return (vc, vm)
    }

    public func makeNicknameEdit() -> NicknameEditPresentable {
        @Dependency var authUsecase: AuthUsecaseProtocol
        let vm = NicknameEditViewModel(authUsecase: authUsecase)
        let vc = NicknameEditViewController(viewModel: vm)
        return (vc, vm)
    }
}
