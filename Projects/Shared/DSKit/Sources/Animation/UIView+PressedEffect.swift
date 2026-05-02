//
//  UIView+PressedEffect.swift
//  DSKit
//
//  Created by Codex on 4/20/26.
//

import ObjectiveC
import UIKit

private final class PressEffectGestureHandler: NSObject {
    weak var view: UIView?
    let pressedScale: CGFloat

    init(view: UIView, pressedScale: CGFloat) {
        self.view = view
        self.pressedScale = pressedScale
    }

    @objc func handlePress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            animate(pressed: true)
        case .ended, .cancelled, .failed:
            animate(pressed: false)
        default:
            break
        }
    }

    private func animate(pressed: Bool) {
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
        addGestureRecognizer(gesture)
    }
}
