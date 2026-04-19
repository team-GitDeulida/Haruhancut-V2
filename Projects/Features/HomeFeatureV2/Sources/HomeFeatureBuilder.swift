//
//  HomeFeatureBuilder.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/19/26.
//

import HomeFeatureV2Interface
import UIKit
import Core
import Domain

public protocol HomeFeatureBuildable {
    func makeHome() -> HomePresentable
}

public final class HomeFeatureBuilder {
    public init() {}
}

extension HomeFeatureBuilder: HomeFeatureBuildable {
    public func makeHome() -> HomePresentable {
        let reactor = HomeReactor()
        let vc = HomeViewController(reactor: reactor)
        return (vc, reactor)
    }
}
