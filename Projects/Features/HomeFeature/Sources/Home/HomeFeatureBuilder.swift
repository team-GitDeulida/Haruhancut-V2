//
//  HomeFeatureBuilder.swift
//  Home
//
//  Created by 김동현 on 
//

import HomeFeatureInterface
import UIKit

public protocol HomeFeatureBuildable {
    func makeHome() -> HomePresentable
}

public final class HomeFeatureBuilder {
    
    public init() {}
    
}

extension HomeFeatureBuilder: HomeFeatureBuildable {
    public func makeHome() -> HomePresentable {
        // return HomeInteractor()
        let vm = HomeViewModel()
        let vc = HomeViewController(viewModel: vm)
        return (vc, vm)
    }
}
