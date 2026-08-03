//
//  Touchable.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// `Touchable` UIView에 lazy하게 설치되는 내부 tap recognizer입니다.
///
/// recognizer가 이벤트 저장소도 함께 소유하므로 별도의 associated
/// object가 필요하지 않습니다. 최초 `.onTouch` 렌더링 때 한 번만
/// 설치되며, 하위 `UIControl`에서 시작한 터치는 버튼과 스위치의 기본
/// 동작에 맡깁니다.
@MainActor
private final class ComponentTouchGestureRecognizer:
    UITapGestureRecognizer,
    UIGestureRecognizerDelegate
{
    let event = ComponentEvent<Void>()

    private weak var contentView: UIView?

    /// Content View 내부의 탭만 전달할 recognizer를 만듭니다.
    ///
    /// - Parameter contentView: 제스처를 감지할 Component Content View.
    init(contentView: UIView) {
        self.contentView = contentView
        super.init(target: nil, action: nil)

        addTarget(self, action: #selector(didRecognizeTouch))
        cancelsTouchesInView = false
        delegate = self
    }

    /// Storyboard와 nib 기반 초기화는 지원하지 않습니다.
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    /// UIControl에서 시작한 터치를 제외하고 Content 내부 터치만 수신합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 수신 여부를 판단하는 tap recognizer.
    ///   - touch: 새로 시작된 터치.
    /// - Returns: Component 전체 탭으로 처리할지 여부.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let contentView else {
            return false
        }

        return shouldReceiveComponentInteraction(
            touchedView: touch.view,
            within: contentView
        )
    }

    /// 실제 long press 동작이 우선 인식되도록 탭의 실패 대기 여부를 판단합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 현재 tap recognizer.
    ///   - otherGestureRecognizer: 우선순위를 비교할 상대 recognizer.
    /// - Returns: 상대 recognizer가 실패한 뒤 탭을 인식할지 여부.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let longPressGestureRecognizer =
            otherGestureRecognizer as? UILongPressGestureRecognizer else {
            return false
        }

        // 0초 long press는 눌림 효과를 표시하기 위한 시각적 recognizer입니다.
        // 삭제처럼 실제 동작을 수행하는 long press가 인식되면 전체 Content의
        // tap은 실패하도록 기다려 두 동작이 함께 실행되지 않게 합니다.
        return longPressGestureRecognizer.minimumPressDuration > 0
    }

    /// Scroll recognizer와 탭 recognizer의 동시 인식 여부를 판단합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 현재 tap recognizer.
    ///   - otherGestureRecognizer: 동시에 인식할지 판단할 상대 recognizer.
    /// - Returns: 두 recognizer의 동시 인식 허용 여부.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer is UIPanGestureRecognizer
            && otherGestureRecognizer.view is UIScrollView
    }

    @objc
    /// 탭이 인식되면 구독자에게 터치 이벤트를 전달합니다.
    private func didRecognizeTouch() {
        event.send(())
    }
}

private extension UIView {
    /// UIView마다 하나만 설치되는 내부 tap recognizer를 반환합니다.
    var componentTouchGestureRecognizer: ComponentTouchGestureRecognizer {
        if let gestureRecognizer = gestureRecognizers?
            .compactMap({ $0 as? ComponentTouchGestureRecognizer })
            .first {
            return gestureRecognizer
        }

        let gestureRecognizer = ComponentTouchGestureRecognizer(contentView: self)
        addGestureRecognizer(gestureRecognizer)
        return gestureRecognizer
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

/// `Touchable` UIView에 기본 터치 이벤트 구현을 제공합니다.
public extension Touchable where Self: UIView {
    /// UIView 수명에 연결된 기본 터치 이벤트입니다.
    ///
    /// 이벤트를 소유한 tap recognizer는 처음 접근할 때 한 번만 설치됩니다.
    var touchEvent: ComponentEvent<Void> {
        componentTouchGestureRecognizer.event
    }
}

extension Touchable where Self: UIView {
    /// 기본 터치 recognizer를 현재 UIView의 터치 환경에 연결합니다.
    ///
    /// Compositional Layout의 self-sizing 과정에서는 표시 중인 셀이
    /// 일시적으로 display 수명에서 빠졌다가 다시 들어올 수 있습니다.
    /// 기존 recognizer를 다시 연결해 UIKit의 gesture environment에도
    /// 현재 표시 수명을 반영합니다.
    func installTouchHandlingIfNeeded() {
        let gestureRecognizer = componentTouchGestureRecognizer
        removeGestureRecognizer(gestureRecognizer)
        addGestureRecognizer(gestureRecognizer)
    }
}
