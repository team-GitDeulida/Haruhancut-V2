//
//  TextField.swift
//  DSKit
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import ScaleKit

public final class HCTextField: UITextField {
    
    public init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.textColor = .mainWhite
        self.tintColor = .mainWhite
        self.backgroundColor = .gray500
        self.layer.cornerRadius = 10.scaled
        self.addLeftPadding()
        self.setPlaceholderColor(color: .gray200)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UITextField {
    func addLeftPadding() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: DynamicSize.scaledSize(12), height: DynamicSize.scaledSize(50)))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setPlaceholderColor(color: UIColor) {
        guard let string = self.placeholder else {
            return
        }
        attributedPlaceholder = NSAttributedString(string: string, attributes: [.foregroundColor: color])
    }
}
