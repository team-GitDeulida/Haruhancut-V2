//
//  CollectionLayoutDimension.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Compositional Layout dimension을 값으로 보관하기 위한 표현입니다.
public enum CollectionLayoutDimension: Hashable {
    /// Auto Layout self-sizing에 사용할 추정값입니다.
    case estimated(CGFloat)

    /// 고정 크기입니다.
    case absolute(CGFloat)

    /// Container 너비에 대한 비율입니다.
    case fractionalWidth(CGFloat)

    /// Container 높이에 대한 비율입니다.
    case fractionalHeight(CGFloat)

    @MainActor
    var layoutDimension: NSCollectionLayoutDimension {
        switch self {
        case let .estimated(value):
            return .estimated(value)
        case let .absolute(value):
            return .absolute(value)
        case let .fractionalWidth(value):
            return .fractionalWidth(value)
        case let .fractionalHeight(value):
            return .fractionalHeight(value)
        }
    }
}
