//
//  Notification+.swift
//  HomeFeature
//
//  Created by 김동현 on 2/25/26.
//

import UIKit
import RxSwift
import RxCocoa

public enum AppNotification {
    public enum Home {
        public static let commentDidChange = Notification.Name("Home.commentDidChange")
    }
}

public enum NotificationAction: String {
    case add
    case delete
}

// Send
public extension UIViewController {
    func sendNoti(_ name: Notification.Name, action: NotificationAction) {
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: ["action": action.rawValue]
        )
    }
}

// Receive
public extension Reactive where Base: NotificationCenter {
    func observe(_ name: Notification.Name) -> Observable<Notification> {
        notification(name)
    }
}
