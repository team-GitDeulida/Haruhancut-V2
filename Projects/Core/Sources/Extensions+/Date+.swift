//
//  Date+.swift
//  Core
//
//  Created by 김동현 on 1/18/26.
//

import Foundation

public extension Date {
    /// Date -> String 포매팅
    /// - Returns: String
    func toKoreanDateKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: self)
    }
}
