//
//  ContainsButton.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Content 안에 별도 버튼 동작이 있음을 나타내는 capability입니다.
///
/// 이 프로토콜을 따르는 Content에만 `.onButtonTap` modifier가 노출됩니다.
@MainActor
public protocol ContainsButton: AnyObject {
    /// 내부 버튼이 눌렸을 때 값을 보내는 이벤트입니다.
    var buttonTapEvent: ComponentEvent<Void> { get }
}
