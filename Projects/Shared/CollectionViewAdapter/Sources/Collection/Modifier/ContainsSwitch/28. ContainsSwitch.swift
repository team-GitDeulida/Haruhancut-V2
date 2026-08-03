//
//  28. ContainsSwitch.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Content 안에 토글 동작이 있음을 나타내는 capability입니다.
///
/// 이 프로토콜을 따르는 Content에만 `.onToggle` modifier가 노출됩니다.
@MainActor
public protocol ContainsSwitch: AnyObject {
    /// 내부 스위치 값이 바뀌었을 때 새 값을 보내는 이벤트입니다.
    var switchToggleEvent: ComponentEvent<Bool> { get }
}
