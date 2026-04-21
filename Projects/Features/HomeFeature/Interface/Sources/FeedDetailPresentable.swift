//
//  FeedDetailPresentable.swift
//  HomeFeature
//
//  Created by 김동현 on 2/11/26.
//

import Foundation
import Core
import UIKit
import Domain

public protocol FeedDetailTrigger {
    var onCommentTapped: ((Post) -> Void)? { get set }
    var onImagePreviewTapped: ((String) -> Void)? { get set }
}

public typealias FeedDetailViewModelType = ViewModelType & FeedDetailTrigger

public typealias FeedDetailPresentable = (vc: UIViewController & RefreshableViewController, vm: any FeedDetailViewModelType)
