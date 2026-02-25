//
//  CalendarDetailBuilder.swift
//  HomeFeature
//
//  Created by 김동현 on 2/24/26.
//

import Foundation
import Domain
import Core
import UIKit
import HomeFeatureInterface

public protocol CalendarDetailBuildable {
    func makeCalendarDetail(posts: [Post], selectedDate: Date) -> CalendarDetailPresentable
    func makeComment(post: Post) -> (vc: UIViewController, vm: AnyObject)
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
    
    public func makeComment(post: Domain.Post) -> (vc: UIViewController, vm: AnyObject) {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = CommentViewModel(groupUsecase: groupUsecase, post: post)
        let vc = CommentViewController(commentViewModel: vm)
        return (vc, vm)
    }
    
}
