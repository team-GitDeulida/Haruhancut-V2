//
//  UIFont+.swift
//  DSKit
//
//  Created by 김동현 on 1/11/26.
//

import UIKit

public extension UIFont {

    enum HCFont {
        case black
        case bold
        case extraBold
        case extraLight
        case light
        case medium
        case regular
        case semiBold
        case thin
    }

    static func hcFont(_ font: HCFont, size: CGFloat) -> UIFont {
        switch font {
        case .black:
            return DSKitFontFamily.Pretendard.black.font(size: size)
        case .bold:
            return DSKitFontFamily.Pretendard.bold.font(size: size)
        case .extraBold:
            return DSKitFontFamily.Pretendard.extraBold.font(size: size)
        case .extraLight:
            return DSKitFontFamily.Pretendard.extraLight.font(size: size)
        case .light:
            return DSKitFontFamily.Pretendard.light.font(size: size)
        case .medium:
            return DSKitFontFamily.Pretendard.medium.font(size: size)
        case .regular:
            return DSKitFontFamily.Pretendard.regular.font(size: size)
        case .semiBold:
            return DSKitFontFamily.Pretendard.semiBold.font(size: size)
        case .thin:
            return DSKitFontFamily.Pretendard.thin.font(size: size)
        }
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


