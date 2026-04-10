//
//  Date+.swift
//  Core
//
//  Created by 김동현 on 1/18/26.
//

import Foundation

public extension Date {
    // Core 모듈은 DSKit를 직접 import할 수 없어서 LocalizationKey나
    // String.localized()를 바로 사용할 수 없다.
    // 대신 DSKit framework bundle을 식별자로 찾아 같은 localization key를 직접 조회한다.
    // 이렇게 하면 Core -> DSKit 의존성을 추가하지 않으면서도
    // CSV / Localizable.strings / LocalizationKey.swift 와 동일한 문자열 소스를 바라볼 수 있다.
    private static let dskitLocalizationBundle: Bundle = {
        Bundle(identifier: "com.indextrown.Haruhancut.ui.dskit") ?? .main
    }()

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
        if abs(timeIntervalSinceNow) < 60 {
            // 1분 미만은 RelativeDateTimeFormatter가 원하는 "방금 전 / Just now" 톤으로
            // 떨어지지 않을 수 있어서 별도 key로 관리한다.
            // key 자체는 DSKit의 로컬라이징 리소스에 등록되어 있으므로,
            // 여기서는 위 bundle을 통해 같은 값을 읽어온다.
            return NSLocalizedString(
                "date.relative.just_now",
                bundle: Self.dskitLocalizationBundle,
                comment: "Relative time label shown when a date is within the last minute."
            )
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.locale = .current
        relativeFormatter.unitsStyle = .short // → "5분 전", "2시간 전", "3일 전"
        return relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
}

/*
public extension Date {

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func fromDateKey(_ key: String) -> Date? {
        return dateKeyFormatter.date(from: key)
    }
}
*/
