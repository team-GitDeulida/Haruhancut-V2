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
@MainActor
func shouldReceiveComponentInteraction(
    touchedView: UIView?,
    within contentView: UIView
) -> Bool {
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
