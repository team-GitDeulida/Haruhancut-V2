//
//  NextButton.swift
//  DSKit
//
//  Created by 김동현 on 1/16/26.
//

import UIKit

/// 다음 버튼
public final class HCNextButton: UIButton {
    public init(title: String) {
        super.init(frame: .zero)
        self.configure(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(title: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .mainBlack
        config.baseBackgroundColor = .mainWhite
        
        self.configuration = config
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        self.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseBackgroundColor = button.isHighlighted ? .lightGray : .mainWhite
            button.configuration = updated
        }
    }
}
