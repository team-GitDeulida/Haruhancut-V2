//
//  CellItemModelType.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// Collection view에 표시할 수 있는 모델의 공통 계약입니다.
///
/// `identifier`는 항목의 정체성을 나타내고 `contentVersion`은 같은 항목의
/// 표시 상태가 바뀌었는지 판단할 때 사용합니다.
@MainActor
public protocol CellItemModelType {
    
    /// 같은 section 안에서 항목을 안정적으로 식별하는 값입니다.
    var identifier: AnyHashable { get }
    
    /// 렌더링 결과가 달라질 때 함께 달라져야 하는 값입니다.
    var contentVersion: AnyHashable { get }
}
