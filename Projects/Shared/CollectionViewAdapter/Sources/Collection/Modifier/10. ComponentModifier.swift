//
//  10. ComponentModifier.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// 기존 Component를 감싸 기능을 합성하는 modifier 계약입니다.
///
/// 원본과 같은 Item과 Content를 사용하므로 modifier는 UIView를 새로
/// 감싸지 않고 기존 Content의 생성과 재사용 수명을 그대로 유지합니다.
public protocol ComponentModifier: Component
where
    Wrapped.Content == Content,
    Wrapped.Item == Item
{
    /// modifier가 감싸는 원본 Component 타입입니다.
    associatedtype Wrapped: Component

    /// modifier가 감싸는 원본 Component입니다.
    var wrapped: Wrapped { get }
}

/// 원본 Component의 Item, 높이와 Content 생성을 그대로 전달합니다.
public extension ComponentModifier {
    /// 원본 Component의 Item을 그대로 사용합니다.
    var item: Item {
        wrapped.item
    }

    /// 원본 Component의 추정 높이를 그대로 사용합니다.
    var estimatedHeight: CGFloat {
        wrapped.estimatedHeight
    }

    /// 원본 Component와 동일한 Content를 생성합니다.
    @MainActor
    func createContent() -> Content {
        wrapped.createContent()
    }
}
