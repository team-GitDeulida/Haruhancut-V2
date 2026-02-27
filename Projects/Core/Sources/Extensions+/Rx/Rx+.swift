//
//  Rx+.swift
//  Core
//
//  Created by 김동현 on 2/27/26.
//

import RxSwift
import UIKit
import RxCocoa

extension Reactive where Base: UIView {
    /*
     [이 확장이 없다면 해야하는 방식]
     var imageTapped: Observable<Void> {
         let tapGesture = UITapGestureRecognizer()
         customView.imageView.isUserInteractionEnabled = true
         customView.imageView.addGestureRecognizer(tapGesture)
         return tapGesture.rx.event
             .map { _ in () }
     }
     */
    public var tap: ControlEvent<Void> {
        let gesture = UITapGestureRecognizer()
        base.addGestureRecognizer(gesture)
        base.isUserInteractionEnabled = true
        let source = gesture.rx.event.map { _ in () }
        return ControlEvent(events: source)
    }
}

extension Reactive where Base: UIViewController {

    /// viewDidLoad
    public var didLoad: ControlEvent<Void> {
        let source = methodInvoked(#selector(Base.viewDidLoad))
            .map { _ in }
        return ControlEvent(events: source)
    }

    /// viewWillAppear(_:)
    public var willAppear: ControlEvent<Bool> {
        let source = methodInvoked(#selector(Base.viewWillAppear(_:)))
            .compactMap { $0.first as? Bool }
        return ControlEvent(events: source)
    }

    /// viewDidAppear(_:)
    public var didAppear: ControlEvent<Bool> {
        let source = methodInvoked(#selector(Base.viewDidAppear(_:)))
            .compactMap { $0.first as? Bool }
        return ControlEvent(events: source)
    }

    /// viewWillDisappear(_:)
    public var willDisappear: ControlEvent<Bool> {
        let source = methodInvoked(#selector(Base.viewWillDisappear(_:)))
            .compactMap { $0.first as? Bool }
        return ControlEvent(events: source)
    }

    /// viewDidDisappear(_:)
    public var didDisappear: ControlEvent<Bool> {
        let source = methodInvoked(#selector(Base.viewDidDisappear(_:)))
            .compactMap { $0.first as? Bool }
        return ControlEvent(events: source)
    }
}

