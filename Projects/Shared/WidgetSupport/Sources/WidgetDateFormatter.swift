//
//  WidgetDateFormatter.swift
//  WidgetSupport
//
//  Created by 김동현 on 
//

import Foundation

/*
 Swift statoc let은 lazy initialization으로 처음 접근 시 생성하고 재사용합니다.
 */
public extension Date {
    
    /// Swift statoc let은 lazy initialization으로 처음 접근 시 생성하고 재사용합니다.
    private static let timestampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    private static let dateKeyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    /// 파일 이름에 사용할 DateFormatter
    /// 2026-03-09-12-30-10.jpg
    func widgetTimestamp() -> String {
        return Self.timestampFormatter.string(from: self)
    }
    
    /// 날짜 폴더 키
    /// 2026-03-09
    func widgetDateKey() -> String {
        return Self.dateKeyFormatter.string(from: self)
    }
}



