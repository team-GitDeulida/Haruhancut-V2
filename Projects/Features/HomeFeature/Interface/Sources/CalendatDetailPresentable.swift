//
//  CalendatDetailPresentable.swift
//  HomeFeature
//
//  Created by 김동현 on 2/24/26.
//

import Foundation
import Core
import UIKit
import Domain

public protocol CalendarDetailTrigger {
    var onCommentTapped: ((Post) -> Void)? { get set }
    var onImagePreviewTapped: ((String) -> Void)? { get set }
}

public typealias CalendarDetailViewModelType = ViewModelType & CalendarDetailTrigger
public typealias CalendarDetailPresentable = (vc: UIViewController, vm: any CalendarDetailViewModelType)
