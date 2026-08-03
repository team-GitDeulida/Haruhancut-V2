//
//  ComponentInteraction.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// Content 내부의 실제 터치 지점이 전체 Content 상호작용 대상인지 확인합니다.
///
/// 하위 `UIControl`에서 시작한 터치는 버튼과 스위치의 기본 동작에 맡기고,
/// 일반 하위 뷰에서 시작한 터치만 Content 전체 상호작용으로 처리합니다.
///
/// - Parameters:
///   - touchedView: UIKit이 전달한 최초 터치 대상 view. 터치가 없으면 `nil`입니다.
///   - contentView: 전체 상호작용을 적용할 Component의 최상위 Content View.
/// - Returns: 터치를 Component 전체 상호작용으로 처리해도 되면 `true`.
@MainActor
func shouldReceiveComponentInteraction(touchedView: UIView?, within contentView: UIView) -> Bool {
    var currentView = touchedView
    while let view = currentView {
        if view === contentView {
            return true
        }

        if view is UIControl {
            return false
        }

        currentView = view.superview
    }

    return false
}
