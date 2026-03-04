//
//  MemberFeatureBuilder.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import MemberFeatureInterface
import Core
import Domain

public protocol MemberFeatureBuildable {
    func makeMember() -> MemberPresentable
}

public final class MemberFeatureBuilder {
    public init() {}
}

extension MemberFeatureBuilder: MemberFeatureBuildable {
    public func makeMember() -> MemberPresentable {
        @Dependency var userSession: UserSession
        @Dependency var groupSession: GroupSession
        @Dependency var authUsecase: AuthUsecaseProtocol
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = MemberViewModel(userSession: userSession,
                                 groupSession: groupSession,
                                 authUsecase: authUsecase,
                                 groupUsecase: groupUsecase)
        let vc = MemberViewController(viewModel: vm)
        return (vc, vm)
    }
}
