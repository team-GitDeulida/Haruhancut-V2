//
//  FeedDetailBuilder.swift
//  HomeFeature
//
//  Created by 김동현 on 2/11/26.
//

import Foundation
import HomeFeatureInterface
import Domain
import UIKit

public protocol FeedDetailBuildable {
    func makeFeed(vm: any HomeViewModelType, post: Post) -> UIViewController
}

public final class FeedDetailBuilder {
    public init() {}
}

extension FeedDetailBuilder: FeedDetailBuildable {
    public func makeFeed(vm: any HomeViewModelType, post: Post) -> UIViewController {
        let vc = FeedDetailViewController(homeViewModel: vm,
                                          post: post)
        return vc
    }
}
