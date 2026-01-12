//
//  UIFont+.swift
//  DSKit
//
//  Created by 김동현 on 1/11/26.
//

import UIKit

public extension UIFont {
    enum HCFont: String {
        case black = "Pretendard-Black"
        case bold = "Pretendard-Bold"
        case extraBold = "Pretendard-ExtraBold"
        case extraLight = "Pretendard-ExtraLight"
        case light = "Pretendard-Light"
        case medium = "Pretendard-Medium"
        case regular = "Pretendard-Regular"
        case semiBold = "Pretendard-SemiBold"
        case thin = "Pretendard-Thin"
    }
}

public extension UIFont {
    static func hcFont(_ font: HCFont, size: CGFloat) -> UIFont {
        return UIFont(name: font.rawValue, size: size)!
    }
}

public extension UIFont {
    static var logoFont: UIFont {
        hcFont(.bold, size: 24)
    }
    static var titleFont: UIFont {
        hcFont(.bold, size: 20)
    }
    static var bodyFont: UIFont {
        hcFont(.regular, size: 15)
    }
    static var captionFont: UIFont {
        hcFont(.medium, size: 12)
    }
}


