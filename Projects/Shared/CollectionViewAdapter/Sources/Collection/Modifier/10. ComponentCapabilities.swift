//
//  ComponentCapabilities.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Content 내부의 실제 터치 지점이 전체 Content 상호작용 대상인지 확인합니다.
///
/// 하위 `UIControl`에서 시작한 터치는 버튼과 스위치의 기본 동작에 맡기고,
/// 일반 하위 뷰에서 시작한 터치만 Content 전체 상호작용으로 처리합니다.
@MainActor
func shouldReceiveComponentInteraction(
    touchedView: UIView?,
    within contentView: UIView
) -> Bool {
    var currentView = touchedView
    while let view = currentView {
        if view === contentView {
            return true
        }

        if view is UIControl {
            return false
        }

        currentView = view.superview
    }

    return false
}

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

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(target: nil, action: nil)

        addTarget(
            self,
            action: #selector(didRecognizeTouch)
        )
        cancelsTouchesInView = false
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

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

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        guard
            let longPressGestureRecognizer =
                otherGestureRecognizer as?
                    UILongPressGestureRecognizer
        else {
            return false
        }

        // 0초 long press는 눌림 효과를 표시하기 위한 시각적 recognizer입니다.
        // 삭제처럼 실제 동작을 수행하는 long press가 인식되면 전체 Content의
        // tap은 실패하도록 기다려 두 동작이 함께 실행되지 않게 합니다.
        return longPressGestureRecognizer
            .minimumPressDuration > 0
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer
            is UIPanGestureRecognizer
            && otherGestureRecognizer.view
                is UIScrollView
    }

    @objc
    private func didRecognizeTouch() {
        event.send(())
    }
}

private extension UIView {
    /// UIView마다 하나만 설치되는 내부 tap recognizer를 반환합니다.
    var componentTouchGestureRecognizer:
        ComponentTouchGestureRecognizer
    {
        if let gestureRecognizer = gestureRecognizers?
            .compactMap({
                $0 as? ComponentTouchGestureRecognizer
            })
            .first
        {
            return gestureRecognizer
        }

        let gestureRecognizer =
            ComponentTouchGestureRecognizer(
                contentView: self
            )
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

/// Content 전체가 눌림 시각 효과를 지원함을 나타내는 capability입니다.
///
/// 프로토콜 채택만으로 효과가 설치되지는 않습니다. `Component` 구성 지점에서
/// `.pressedEffect()` modifier를 사용했을 때만 눌림 recognizer가 연결됩니다.
@MainActor
public protocol Pressable: AnyObject {}

/// `Pressable` Content에 lazy하게 설치되는 내부 눌림 recognizer입니다.
///
/// 터치가 시작되면 Content를 축소하고, 종료되거나 스크롤로 판단되면 원래
/// 크기로 복원합니다. 하위 `UIControl`의 터치는 시각 효과 대상에서 제외합니다.
@MainActor
private final class ComponentPressedEffectGestureRecognizer:
    UILongPressGestureRecognizer,
    UIGestureRecognizerDelegate
{
    private enum Constant {
        static let scrollCancellationDistance:
            CGFloat = 10
        static let animationDuration:
            TimeInterval = 0.12
    }

    private weak var contentView: UIView?
    private var pressedScale: CGFloat
    private var initialLocation: CGPoint?
    private var isPressed = false

    init(
        contentView: UIView,
        pressedScale: CGFloat
    ) {
        self.contentView = contentView
        self.pressedScale = pressedScale
        super.init(target: nil, action: nil)

        addTarget(
            self,
            action: #selector(handlePress)
        )
        minimumPressDuration = 0
        cancelsTouchesInView = false
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    func updatePressedScale(
        _ pressedScale: CGFloat
    ) {
        self.pressedScale = pressedScale
    }

    @objc
    private func handlePress() {
        switch state {
        case .began:
            initialLocation =
                location(in: contentView)
            updatePressedState(true)

        case .changed:
            guard
                let contentView,
                let initialLocation
            else {
                return
            }

            let currentLocation =
                location(in: contentView)
            let distance = hypot(
                currentLocation.x
                    - initialLocation.x,
                currentLocation.y
                    - initialLocation.y
            )
            if distance >=
                Constant
                    .scrollCancellationDistance
            {
                updatePressedState(false)
            }

        case .ended, .cancelled, .failed:
            initialLocation = nil
            updatePressedState(false)

        default:
            break
        }
    }

    private func updatePressedState(
        _ pressed: Bool
    ) {
        guard isPressed != pressed else {
            return
        }
        isPressed = pressed

        guard let contentView else {
            return
        }

        let targetScale:
            CGFloat = pressed
                ? pressedScale
                : 1
        UIView.animate(
            withDuration:
                Constant.animationDuration,
            delay: 0,
            options: [
                .allowUserInteraction,
                .beginFromCurrentState,
                .curveEaseOut,
            ]
        ) {
            contentView.transform =
                CGAffineTransform(
                    scaleX: targetScale,
                    y: targetScale
                )
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer:
            UIGestureRecognizer,
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

    func gestureRecognizer(
        _ gestureRecognizer:
            UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
            otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer
            is UITapGestureRecognizer
            || otherGestureRecognizer
                is UILongPressGestureRecognizer
        {
            return true
        }

        return otherGestureRecognizer
            is UIPanGestureRecognizer
            && otherGestureRecognizer.view
                is UIScrollView
    }
}

extension Pressable where Self: UIView {
    /// 눌림 recognizer를 UIView 수명 동안 한 번만 설치하고 최신 scale을 반영합니다.
    func installPressedEffectIfNeeded(
        scale: CGFloat
    ) {
        guard scale > 0, scale < 1 else {
            return
        }

        isUserInteractionEnabled = true

        if let gestureRecognizer =
            gestureRecognizers?
                .compactMap({
                    $0 as?
                        ComponentPressedEffectGestureRecognizer
                })
                .first
        {
            gestureRecognizer
                .updatePressedScale(scale)
            return
        }

        addGestureRecognizer(
            ComponentPressedEffectGestureRecognizer(
                contentView: self,
                pressedScale: scale
            )
        )
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
