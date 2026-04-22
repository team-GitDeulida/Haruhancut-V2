//
//  CalendarDetailPresentable.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import Core
import Domain

public protocol CalendarDetailTrigger {
    var onCommentTapped: ((Post) -> Void)? { get set }
    var onImagePreviewTapped: ((String) -> Void)? { get set }
}

public typealias CalendarDetailViewModelType = ViewModelType & CalendarDetailTrigger

public typealias CalendarDetailPresentable = (vc: UIViewController & RefreshableViewController, vm: any CalendarDetailViewModelType)
