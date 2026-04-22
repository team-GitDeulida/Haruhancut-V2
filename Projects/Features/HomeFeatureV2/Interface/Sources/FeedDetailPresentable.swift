//
//  FeedDetailPresentable.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import Core
import Domain

public protocol FeedDetailTrigger {
    var onCommentTapped: ((Post) -> Void)? { get set }
    var onImagePreviewTapped: ((String) -> Void)? { get set }
}

public typealias FeedDetailViewModelType = ViewModelType & FeedDetailTrigger

public typealias FeedDetailPresentable = (vc: UIViewController & RefreshableViewController, vm: any FeedDetailViewModelType)
