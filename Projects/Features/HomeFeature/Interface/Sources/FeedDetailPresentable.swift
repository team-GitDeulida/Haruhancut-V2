//
//  FeedDetailPresentable.swift
//  HomeFeature
//
//  Created by 김동현 on 2/11/26.
//

import Foundation
import Core
import UIKit

public protocol FeedDetailTrigger {
    var onCommentTapped: (() -> Void)? { get set }
    var onImagePreviewTapped: ((String) -> Void)? { get set }
}

public typealias FeedDetailViewModelType = ViewModelType & FeedDetailTrigger

public typealias FeedDetailPresentable = (vc: UIViewController, vm: any FeedDetailViewModelType)
