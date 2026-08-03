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

    /// Content View의 눌림 효과를 관리할 recognizer를 만듭니다.
    ///
    /// - Parameters:
    ///   - contentView: 눌림 효과를 적용할 Component Content View.
    ///   - pressedScale: 터치 중 적용할 축소 비율.
    init(contentView: UIView, pressedScale: CGFloat) {
        self.contentView = contentView
        self.pressedScale = pressedScale
        super.init(target: nil, action: nil)

        addTarget(self, action: #selector(handlePress))
        minimumPressDuration = 0
        cancelsTouchesInView = false
        delegate = self
    }

    /// Storyboard와 nib 기반 초기화는 지원하지 않습니다.
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    /// 눌림 효과에 사용할 축소 비율을 최신 값으로 변경합니다.
    ///
    /// - Parameter pressedScale: 터치 중 적용할 새 축소 비율.
    func updatePressedScale(_ pressedScale: CGFloat) {
        self.pressedScale = pressedScale
    }

    @objc
    /// 제스처 상태에 따라 눌림 효과를 시작·취소·종료합니다.
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

    /// 현재 눌림 상태를 반영해 Content View의 scale transform을 애니메이션합니다.
    ///
    /// - Parameter pressed: 눌림 효과를 적용할지 여부.
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

    /// UIControl에서 시작한 터치를 제외하고 Content 내부 터치만 수신합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 수신 여부를 판단하는 눌림 recognizer.
    ///   - touch: 새로 시작된 터치.
    /// - Returns: Content 전체 눌림 효과로 처리할지 여부.
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

    /// 탭, long press, scroll recognizer와 함께 동작할 수 있는지 판단합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 현재 눌림 recognizer.
    ///   - otherGestureRecognizer: 동시에 인식할지 판단할 상대 recognizer.
    /// - Returns: 두 recognizer의 동시 인식 허용 여부.
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
