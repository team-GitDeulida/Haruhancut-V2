//
//  UIView+PressedEffect.swift
//  DSKit
//
//  Created by Codex on 4/20/26.
//

import ObjectiveC
import UIKit

private final class PressEffectGestureHandler:
    NSObject,
    UIGestureRecognizerDelegate
{
    private enum Constant {
        static let scrollCancellationDistance:
            CGFloat = 10
    }

    weak var view: UIView?
    let pressedScale: CGFloat
    private var initialLocation: CGPoint?
    private var isPressed = false

    init(view: UIView, pressedScale: CGFloat) {
        self.view = view
        self.pressedScale = pressedScale
    }

    @objc func handlePress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialLocation =
                gesture.location(in: view)
            updatePressedState(true)

        case .changed:
            guard
                let view,
                let initialLocation
            else {
                return
            }

            let currentLocation =
                gesture.location(in: view)
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

        guard let view else { return }

        let targetScale: CGFloat = pressed ? pressedScale : 1
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            view.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
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

private enum AssociatedKeys {
    static var pressedEffectHandler = 0
}

public extension UIView {
    func enablePressedEffect(scale: CGFloat = 0.97) {
        guard scale < 1 else { return }

        isUserInteractionEnabled = true

        if objc_getAssociatedObject(self, &AssociatedKeys.pressedEffectHandler) != nil {
            return
        }

        let handler = PressEffectGestureHandler(view: self, pressedScale: scale)
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.pressedEffectHandler,
            handler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        let gesture = UILongPressGestureRecognizer(
            target: handler,
            action: #selector(PressEffectGestureHandler.handlePress(_:))
        )
        gesture.minimumPressDuration = 0
        gesture.cancelsTouchesInView = false
        gesture.delegate = handler
        addGestureRecognizer(gesture)
    }
}
