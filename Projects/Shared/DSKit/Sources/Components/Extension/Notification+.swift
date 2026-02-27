//
//  Notification+.swift
//  HomeFeature
//
//  Created by 김동현 on 2/25/26.
//

import UIKit

public extension Notification.Name {
    static let homeCommentDidChange = Notification.Name("Home.commentDidChange")
}

public enum NotificationAction: String {
    case add
    case delete
}

public extension UIViewController {
    func sendNoti(action: NotificationAction) {
        NotificationCenter.default.post(name: .homeCommentDidChange, object: nil, userInfo: ["action": action.rawValue])
    }
}
