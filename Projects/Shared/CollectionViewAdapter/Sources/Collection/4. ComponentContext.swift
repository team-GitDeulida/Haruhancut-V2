//
//  ComponentContext.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import Foundation

/// 한 번의 render 수명 동안 생성된 작업을 정리하는 저장소입니다.
///
/// RxSwift의 `DisposeBag`이 담당하던 render 단위 정리를 외부 라이브러리 없이
/// 수행합니다.
@MainActor
public final class ComponentCancellationBag {
    
    private var cancellations: [() -> Void] = []
    
    /// 취소 동작을 저장합니다.
    ///
    /// - Parameter cancellation: render 수명이 끝날 때 실행할 동작.
    public func store(_ cancellation: @escaping () -> Void) {
        cancellations.append(cancellation)
    }
    
    /// Event observation을 저장합니다.
    ///
    /// - Parameter observation: 취소할 event observation.
    public func store(_ observation: ComponentEventObservation) {
        store {
            observation.cancel()
        }
    }
    
    /// 저장된 모든 작업을 한 번씩 취소하고 저장소를 비웁니다.
    public func cancelAll() {
        let pending = cancellations
        cancellations.removeAll()
        pending.forEach { $0() }
    }
}

import UIKit

/// Component의 한 번의 render에 필요한 환경과 수명을 제공합니다.
@MainActor
public final class ComponentContext {
    
    /// Component를 표시하는 collection view입니다.
    public weak var collectionView: UICollectionView?
    
    /// Collection view 안에서 Component가 표시되는 위치입니다.
    public let indexPath: IndexPath?
    
    /// Collection view 안에서 Component가 표시되는 위치입니다.
    public let sectionIdentifier: AnyHashable?
    
    /// 현재 render에서 만든 event 연결과 비동기 작업을 보관합니다.
    public let cancellationBag = ComponentCancellationBag()
    
    private let layoutInvalidation: () -> Void
    
    /// Component render context를 생성합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Component를 표시하는 collection view.
    ///   - indexPath: Component가 표시되는 index path.
    ///   - sectionIdentifier: Component가 속한 section ID.
    ///   - layoutInvalidation: Layout 재계산 요청을 처리할 동작.
    public init(
        collectionView: UICollectionView? = nil,
        indexPath: IndexPath? = nil,
        sectionIdentifier: AnyHashable? = nil,
        layoutInvalidation: @escaping () -> Void = {}
    ) {
        self.collectionView = collectionView
        self.indexPath = indexPath
        self.sectionIdentifier = sectionIdentifier
        self.layoutInvalidation = layoutInvalidation
    }
    
    /// Content 크기가 바뀌었을 때 layout 재계산을 요청합니다.
    public func invalidateLayout() {
        layoutInvalidation()
    }
    
    /// 현재 render 수명에 연결된 작업을 모두 취소합니다.
    public func cancel() {
        cancellationBag.cancelAll()
    }
}
