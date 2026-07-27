//
//  HomePresentable.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/19/26.
//

import UIKit
import Core
import Domain

public enum CameraSource {
    case camera
    case album
}

/// Home 화면이 데이터를 조회하고 상호작용하는 범위입니다.
public enum HomePresentationMode:
    Equatable
{
    /// 현재 로그인 사용자의 그룹을 표시합니다.
    case currentGroup

    /// 관리자가 지정한 그룹을 세션 변경 없이 읽기 전용으로 표시합니다.
    case adminPreview(
        groupID: String
    )

    public var isReadOnly: Bool {
        if case .adminPreview = self {
            return true
        }
        return false
    }
}

public protocol HomeRouteTrigger: AnyObject {
    var onImageTapped: ((Post) -> Void)? { get set }
    var onMemberTapped: (() -> Void)? { get set }
    var onProfileTapped: (() -> Void)? { get set }
    var onCameraTapped: ((CameraSource) -> Void)? { get set }
    var onCalendarImageTapped: (([Post], Date) -> Void)? { get set }
}

//public typealias HomeReactorType = HomeRouteTrigger
public typealias HomePresentable = (UIViewController)
