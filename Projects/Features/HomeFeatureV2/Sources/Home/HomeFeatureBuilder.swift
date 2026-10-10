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
import RxSwift

public protocol HomeFeatureBuildable {
    func makeHome(routeTrigger: HomeRouteTrigger?) -> HomePresentable
    func makeHome(
        mode: HomePresentationMode,
        routeTrigger: HomeRouteTrigger?
    ) -> HomePresentable
}

public final class HomeFeatureBuilder {
    public init() {}
}

extension HomeFeatureBuilder: HomeFeatureBuildable {
    public func makeHome(routeTrigger: HomeRouteTrigger? = nil) -> HomePresentable {
        makeHome(
            mode: .currentGroup,
            routeTrigger: routeTrigger
        )
    }

    public func makeHome(
        mode: HomePresentationMode,
        routeTrigger: HomeRouteTrigger? = nil
    ) -> HomePresentable {
        @Dependency
        var groupUsecase:
            GroupUsecaseProtocol
        @Dependency
        var widgetUsecase:
            WidgetUsecaseProtocol

        let loadGroup =
            HomeGroupLoaderFactory
                .make(
                    mode: mode,
                    groupUsecase:
                        groupUsecase
                )

        let feedReactor =
            FeedReactor(
                loadGroup: loadGroup,
                groupUsecase:
                    mode.isReadOnly
                    ? nil
                    : groupUsecase,
                // 관리자 미리보기는 다른 그룹을 표시하므로 내 위젯을 덮어쓰지 않습니다.
                widgetUsecase:
                    mode.isReadOnly
                    ? nil
                    : widgetUsecase
            )
        let calendarReactor =
            CalendarReactor(
                loadGroup: loadGroup
            )
        let vc =
            HomeViewController(
                feedReactor:
                    feedReactor,
                calendarReactor:
                    calendarReactor,
                mode: mode
            )
        vc.routeTrigger = routeTrigger
        return vc
    }
}
