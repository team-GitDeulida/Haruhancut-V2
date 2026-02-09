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
    
    /// Date -> String 포매팅
    /// - Returns: String
    func toDateKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// 그룹만들때 사용됨
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
    
    /// 상대적인 시간
    /// - Returns: "5분 전", "2시간 전", "3일 전"
    func toRelativeString() -> String {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.locale = Locale(identifier: "ko_KR")
        relativeFormatter.unitsStyle = .short // → "5분 전", "2시간 전", "3일 전"
        return relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
}
