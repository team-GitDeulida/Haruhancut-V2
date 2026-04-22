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
    func makeComment(post: Post, onDismiss: (() -> Void)?) -> UIViewController
}

public final class CalendarDetailBuilder {
    public init() {}
}

extension CalendarDetailBuilder: CalendarDetailBuildable {
    public func makeCalendarDetail(posts: [Post], selectedDate: Date) -> CalendarDetailPresentable {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = CalendarDetailViewModel(groupUsecase: groupUsecase,
                                         posts: posts,
                                         selectedDate: selectedDate)
        let vc = CalendarDetailViewController(viewModel: vm)
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
