//
//  UIView+.swift
//  Core
//
//  Created by 김동현 on 1/17/26.
//

import UIKit

public extension UIView {
    func bindKeyboard(to constraint: NSLayoutConstraint, offset: CGFloat = 10) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self,
                  let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            let bottomInset = keyboardFrame.height - self.safeAreaInsets.bottom
            constraint.constant = -bottomInset - offset
            
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            constraint.constant = -offset
            
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
}

// button.uiTestID(UITestID.Home.cameraButton)
public extension UIView {
    @discardableResult
    func uiTestID(_ id: String) -> Self {
        // self.isAccessibilityElement = true
        self.accessibilityIdentifier = id
        return self
    }
}
