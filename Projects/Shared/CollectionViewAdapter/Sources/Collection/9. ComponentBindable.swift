//
//  ComponentBindable.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// Type-erased Component를 UIKit cell container에 연결하는 내부 계약입니다.
///
/// Collection view cell의 generic `ContainerCell`이 이 계약을 구현합니다.
@MainActor
protocol CellComponentBindable: AnyObject {
    
    /// 모델에서 구체 Component를 복원하고 Content를 생성 또는 갱신합니다.
    ///
    /// - Parameter component: Container에 표시할 type-erased Component.
    func bind(component: AnyComponent)
}

/// Adapter가 bind 직전에 ComponentContext를 container에 전달하는 내부 계약입니다.
@MainActor
protocol ComponentContextBindable: AnyObject {
    var bindingContext: ComponentContext? { get set }
}

/// Supplementary container에 동일한 Component를 연결하는 내부 계약입니다.
///
/// Header와 footer는 Component 종류가 아니라 Section 배치이므로 공개
/// cell binding과 분리된 adapter 내부 경로를 사용합니다.
@MainActor
protocol SupplementaryComponentBindable: AnyObject {
    /// Type-erased Component를 supplementary container에 연결합니다.
    ///
    /// - Parameter component: Container에 표시할 type-erased Component.
    func bind(component: AnyComponent)
}

/// UIKit 표시 수명 이벤트를 container에 전달하는 내부 계약입니다.
@MainActor
protocol ComponentContainerLifecycle: AnyObject {
    /// Container의 Content가 화면에 표시되기 직전에 호출됩니다.
    func contentWillDisplay()

    /// Container의 Content가 화면에서 사라진 직후에 호출됩니다.
    func contentDidEndDisplay()
}
