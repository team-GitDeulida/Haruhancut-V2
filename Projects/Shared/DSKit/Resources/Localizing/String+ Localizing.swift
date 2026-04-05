//
//  Localizing+.swift
//  DSKit
//
//  Created by 김동현 on 4/5/26.
//

import Foundation

public extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, bundle: .main, comment: comment)
    }
}
