//
//  UIColor+.swift
//  DSKit
//
//  Created by 김동현 on 1/11/26.
//

import UIKit

// MARK: - Hex -> UIColor
public extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

public extension UIColor {
    
    // MARK: - Login
    static let kakao = UIColor(hex: "#FEE500")
    static let apple = UIColor(hex: "#FFFFFF")
    static let kakaoTapped = UIColor(hex: "#CCC200")
    static let appleTapped = UIColor(hex: "#E5E5E5")
    
    // MARK: - Main
    static let background = UIColor(hex: "#1A1A1A")
    static let mainBlack = UIColor(hex: "#161717")
    static let mainWhite = UIColor(hex: "#f1f1f1")
    static let buttonTapped = UIColor(hex: "#131315")
    static let hcColor = UIColor.init(hex: "AAD1E7")
    
    // MARK: - Gray
    static let gray000 = UIColor(hex: "#EFEFEF")
    static let gray100 = UIColor(hex: "#B0AEB3")
    static let gray200 = UIColor(hex: "#8B888F")
    static let gray300 = UIColor(hex: "#67646C")
    static let gray500 = UIColor(hex: "#454348")
    static let gray700 = UIColor(hex: "#252427")
    static let gray900 = UIColor(hex: "#111113")
}
