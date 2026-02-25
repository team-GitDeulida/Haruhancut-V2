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
import Core

public protocol FeedDetailBuildable {
    func makeFeed(post: Post) -> FeedDetailPresentable
    func makeComment(post: Post) -> UIViewController
}

public final class FeedDetailBuilder {
    public init() {}
}

extension FeedDetailBuilder: FeedDetailBuildable {
    public func makeFeed(post: Post) -> FeedDetailPresentable {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = FeedDetailViewModel(groupUsecase: groupUsecase, post: post)
        let vc = FeedDetailViewController(viewModel: vm)
        return (vc, vm)
    }
    
    public func makeComment(post: Post) -> UIViewController {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = CommentViewModel(groupUsecase: groupUsecase, post: post)
        let vc = CommentViewController(commentViewModel: vm)
        return vc
    }
}
