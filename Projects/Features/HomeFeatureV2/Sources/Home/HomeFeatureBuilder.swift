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
    func makeHome(routeTrigger: HomeRouteTrigger?) -> HomePresentable
}

public final class HomeFeatureBuilder {
    public init() {}
}

extension HomeFeatureBuilder: HomeFeatureBuildable {
    public func makeHome(routeTrigger: HomeRouteTrigger? = nil) -> HomePresentable {
        let feedReactor = FeedReactor()
        let calendarReactor = CalendarReactor()
        let vc = HomeViewController(feedReactor: feedReactor, calendarReactor: calendarReactor)
        vc.routeTrigger = routeTrigger
        return vc
    }
}
