//
//  DSImage.swift
//  DSKit
//
//  Created by 김동현 on 3/5/26.
//

import UIKit

public enum DSImage {

    public static let onboarding1 = image("1")
    public static let onboarding3 = image("3")
    public static let onboarding4 = image("4")
    public static let onboarding5 = image("5")

}

private extension DSImage {

    static func image(_ name: String) -> UIImage {
        guard let image = UIImage(
            named: name,
            in: Bundle.module,
            compatibleWith: nil
        ) else {
            fatalError("❌ DSKit Image not found: \(name)")
        }
        return image
    }
}
