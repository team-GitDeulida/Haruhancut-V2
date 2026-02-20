//
//  UploadBtn.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit

public final class HCUploadButton: UIButton {
    public init(title: String) {
        super.init(frame: .zero)
        self.configure(title: title)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Configure the button's appearance using the provided title.
    /// - Parameter title: The title displayed on the button. Sets foreground to `mainBlack`, background to `mainWhite`, applies a corner radius of 20 and enables clipping, and updates the background to `lightGray` while the button is highlighted.
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