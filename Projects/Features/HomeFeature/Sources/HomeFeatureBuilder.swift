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
        let vc = HomeViewController()
        let vm = HomeViewModel() 
        return (vc, vm)
    }
}

