//
//  ComponentCapabilities.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import ObjectiveC
import UIKit

@MainActor
private enum TouchableAssociatedKeys {
    static var storage: UInt8 = 0
}

/// `Touchable` UIView에 lazy하게 연결되는 내부 터치 저장소입니다.
///
/// 이벤트와 recognizer를 associated object로 UIView 수명에 묶습니다.
/// recognizer는 최초 `.onTouch` 렌더링 때 한 번만 설치되며, 하위
/// `UIControl`에서 시작한 터치는 버튼과 스위치의 기본 동작에 맡깁니다.
@MainActor
private final class TouchableStorage:
    NSObject,
    UIGestureRecognizerDelegate
{
    let event = ComponentEvent<Void>()

    private weak var contentView: UIView?
    private var gestureRecognizer: UITapGestureRecognizer?

    func installIfNeeded(on contentView: UIView) {
        guard gestureRecognizer == nil else {
            return
        }

        self.contentView = contentView

        let gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didRecognizeTouch)
        )
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        contentView.addGestureRecognizer(gestureRecognizer)
        self.gestureRecognizer = gestureRecognizer
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let contentView else {
            return false
        }

        var touchedView = touch.view
        while let view = touchedView {
            if view === contentView {
                return true
            }

            if view is UIControl {
                return false
            }

            touchedView = view.superview
        }

        return false
    }

    @objc
    private func didRecognizeTouch() {
        guard let touchable = contentView as? any Touchable else {
            return
        }

        touchable.touchEvent.send(())
    }
}

private extension UIView {
    /// UIView마다 하나만 존재하는 터치 저장소를 반환합니다.
    var componentTouchableStorage: TouchableStorage {
        if let storage = objc_getAssociatedObject(
            self,
            &TouchableAssociatedKeys.storage
        ) as? TouchableStorage {
            return storage
        }

        let storage = TouchableStorage()
        objc_setAssociatedObject(
            self,
            &TouchableAssociatedKeys.storage,
            storage,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return storage
    }
}

/// Content 전체가 터치될 수 있음을 나타내는 capability입니다.
///
/// UIView Content는 프로토콜을 채택하는 것만으로 기본 터치 이벤트 구현을
/// 얻습니다. 이 프로토콜을 따르는 Content에만 `.onTouch` modifier가
/// 노출됩니다.
@MainActor
public protocol Touchable: AnyObject {
    /// Content가 터치되었을 때 값을 보내는 이벤트입니다.
    var touchEvent: ComponentEvent<Void> { get }
}

public extension Touchable where Self: UIView {
    /// UIView 수명에 연결된 기본 터치 이벤트입니다.
    ///
    /// 저장소는 처음 접근할 때 associated object로 한 번만 만들어집니다.
    var touchEvent: ComponentEvent<Void> {
        componentTouchableStorage.event
    }
}

extension Touchable where Self: UIView {
    /// 기본 터치 recognizer를 UIView에 한 번만 설치합니다.
    func installTouchHandlingIfNeeded() {
        componentTouchableStorage.installIfNeeded(on: self)
    }
}

/// Content 안에 별도 버튼 동작이 있음을 나타내는 capability입니다.
///
/// 이 프로토콜을 따르는 Content에만 `.onButtonTap` modifier가 노출됩니다.
@MainActor
public protocol ContainsButton: AnyObject {
    /// 내부 버튼이 눌렸을 때 값을 보내는 이벤트입니다.
    var buttonTapEvent: ComponentEvent<Void> { get }
}

/// Content 안에 토글 동작이 있음을 나타내는 capability입니다.
///
/// 이 프로토콜을 따르는 Content에만 `.onToggle` modifier가 노출됩니다.
@MainActor
public protocol ContainsSwitch: AnyObject {
    /// 내부 스위치 값이 바뀌었을 때 새 값을 보내는 이벤트입니다.
    var switchToggleEvent: ComponentEvent<Bool> { get }
}
