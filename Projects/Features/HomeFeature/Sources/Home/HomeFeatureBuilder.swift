//
//  HomeFeatureBuilder.swift
//  Home
//
//  Created by 김동현 on 
//

import HomeFeatureInterface
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
        // return HomeInteractor()
        @Dependency var gropUsecase: GroupUsecaseProtocol
        @Dependency var authUsecase: AuthUsecaseProtocol
        let vm = HomeViewModel(groupUsecase: gropUsecase,
                               authUsecase: authUsecase)
        let vc = HomeViewController(viewModel: vm)
        return (vc, vm)
    }
}
