//
//  Pressable.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

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
        static let scrollCancellationDistance: CGFloat = 10
        static let animationDuration: TimeInterval = 0.12
    }

    private weak var contentView: UIView?
    private var pressedScale: CGFloat
    private var initialLocation: CGPoint?
    private var isPressed = false

    init(contentView: UIView, pressedScale: CGFloat) {
        self.contentView = contentView
        self.pressedScale = pressedScale
        super.init(target: nil, action: nil)

        addTarget(self, action: #selector(handlePress))
        minimumPressDuration = 0
        cancelsTouchesInView = false
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    func updatePressedScale(_ pressedScale: CGFloat) {
        self.pressedScale = pressedScale
    }

    @objc
    private func handlePress() {
        switch state {
        case .began:
            initialLocation = location(in: contentView)
            updatePressedState(true)

        case .changed:
            guard
                let contentView,
                let initialLocation
            else {
                return
            }

            let currentLocation = location(in: contentView)
            let distance = hypot(
                currentLocation.x - initialLocation.x,
                currentLocation.y - initialLocation.y
            )
            if distance >= Constant.scrollCancellationDistance {
                updatePressedState(false)
            }

        case .ended, .cancelled, .failed:
            initialLocation = nil
            updatePressedState(false)

        default:
            break
        }
    }

    private func updatePressedState(_ pressed: Bool) {
        guard isPressed != pressed else {
            return
        }
        isPressed = pressed

        guard let contentView else {
            return
        }

        let targetScale: CGFloat = pressed ? pressedScale : 1
        UIView.animate(
            withDuration: Constant.animationDuration,
            delay: 0,
            options: [
                .allowUserInteraction,
                .beginFromCurrentState,
                .curveEaseOut,
            ]
        ) {
            contentView.transform = CGAffineTransform(
                scaleX: targetScale,
                y: targetScale
            )
        }
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
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer
            || otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }

        return otherGestureRecognizer is UIPanGestureRecognizer
            && otherGestureRecognizer.view is UIScrollView
    }
}

extension Pressable where Self: UIView {
    /// 눌림 recognizer를 UIView 수명 동안 한 번만 설치하고 최신 scale을 반영합니다.
    func installPressedEffectIfNeeded(scale: CGFloat) {
        guard scale > 0, scale < 1 else {
            return
        }

        isUserInteractionEnabled = true

        if let gestureRecognizer = gestureRecognizers?
            .compactMap({ $0 as? ComponentPressedEffectGestureRecognizer })
            .first {
            gestureRecognizer.updatePressedScale(scale)
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
