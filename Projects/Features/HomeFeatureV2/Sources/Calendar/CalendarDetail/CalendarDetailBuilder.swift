//
//  CalendarDetailBuilder.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import Foundation
import Domain
import Core
import UIKit
import HomeFeatureV2Interface

public protocol CalendarDetailBuildable {
    func makeCalendarDetail(posts: [Post], selectedDate: Date) -> CalendarDetailPresentable
    func makeCalendarDetail(
        posts: [Post],
        selectedDate: Date,
        mode:
            HomePresentationMode
    ) -> CalendarDetailPresentable
    func makeComment(post: Post, onDismiss: (() -> Void)?) -> UIViewController
}

public final class CalendarDetailBuilder {
    public init() {}
}

extension CalendarDetailBuilder: CalendarDetailBuildable {
    public func makeCalendarDetail(posts: [Post], selectedDate: Date) -> CalendarDetailPresentable {
        makeCalendarDetail(
            posts: posts,
            selectedDate:
                selectedDate,
            mode: .currentGroup
        )
    }

    public func makeCalendarDetail(
        posts: [Post],
        selectedDate: Date,
        mode:
            HomePresentationMode
    ) -> CalendarDetailPresentable {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let loadGroup =
            HomeGroupLoaderFactory
                .make(
                    mode: mode,
                    groupUsecase:
                        groupUsecase
                )
        let vm =
            CalendarDetailViewModel(
                loadGroup: loadGroup,
                posts: posts,
                selectedDate:
                    selectedDate
            )
        let vc =
            CalendarDetailViewController(
                viewModel: vm,
                isReadOnly:
                    mode.isReadOnly
            )
        return (vc, vm)
    }

    public func makeComment(post: Domain.Post, onDismiss: (() -> Void)? = nil) -> UIViewController {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = CommentViewModel(groupUsecase: groupUsecase, post: post)
        let vc = CommentViewController(commentViewModel: vm)
        vc.onDismiss = onDismiss
        return vc
    }
}
