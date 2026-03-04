//
//  MemberFeatureBuilder.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import MemberFeatureInterface

public protocol MemberFeatureBuildable {
    func makeMember() -> MemberPresentable
}

public final class MemberFeatureBuilder {
    public init() {}
}

extension MemberFeatureBuilder: MemberFeatureBuildable {
    public func makeMember() -> MemberPresentable {
        let vm = MemberViewModel()
        let vc = MemberViewController(viewModel: vm)
        return (vc, vm)
    }
}
