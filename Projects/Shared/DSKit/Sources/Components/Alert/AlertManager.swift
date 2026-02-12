//
//  AlertManager.swift
//  DSKit
//
//  Created by 김동현 on 2/12/26.
//

import UIKit

/*
 let alert = DSAlertFactory.makeAlert(
     title: "삭제하시겠습니까?",
     message: nil,
     preferredStyle: .alert,
     actions: [
         UIAlertAction(title: "취소", style: .cancel),
         UIAlertAction(title: "삭제", style: .destructive) { _ in
             print("삭제됨")
         }
     ]
 )

 present(alert, animated: true)
 */
public enum AlertFactory {
    public static func makeAlert(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style = .alert,
        actions: [UIAlertAction]
    ) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: preferredStyle)
        actions.forEach { alert.addAction($0) }
        return alert
    }
}
