//
//  FeedDetailBuilder.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import Foundation
import HomeFeatureV2Interface
import Domain
import UIKit
import Core

public protocol FeedDetailBuildable {
    func makeFeed(post: Post) -> FeedDetailPresentable
    func makeComment(post: Post, onDismiss: (() -> Void)?) -> UIViewController
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
    
    public func makeComment(post: Post, onDismiss: (() -> Void)? = nil) -> UIViewController {
        @Dependency var groupUsecase: GroupUsecaseProtocol
        let vm = CommentViewModel(groupUsecase: groupUsecase, post: post)
        let vc = CommentViewController(commentViewModel: vm)
        vc.onDismiss = onDismiss
        return vc
    }
}
