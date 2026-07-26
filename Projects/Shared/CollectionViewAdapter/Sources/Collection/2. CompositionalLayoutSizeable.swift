//
//  CompositionalLayoutSizeable.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// Component의 self-sizing 초기 추정값을 제공하는 계약입니다.
///
/// Compositional Layout 환경에서 항목의 초기 추정 크기를 표현하는
/// 프로토콜입니다. 실제 높이는 Auto Layout self-sizing으로 결정되며
/// 이 값은 `estimated` dimension의 초기값으로 사용됩니다.
public protocol CompositionalLayoutSizeable {
    
    /// Compositional Layout이 최초 크기 계산에 사용할 추정 높이입니다.
    var estimatedHeight: CGFloat { get }
}

public extension CompositionalLayoutSizeable {
    
    /// 별도 지정이 없을 때 사용하는 기본 추정 높이입니다.
    var estimatedHeight: CGFloat { 44 }
}
