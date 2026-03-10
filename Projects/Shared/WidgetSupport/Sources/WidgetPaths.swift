//
//  WidgetPaths.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Foundation

public enum WidgetPaths {
    
    /// 앱과 위젯이 데이터를 공유하기 위한 App Group 식별자입니다
    /// 기본적으로 iOS 는App sandbox <-> Widget sandbox가 서로 분리되어 있어 파일 접근이 안됩니다
    /// Apple이 제공하는 공유 영역인 App Group을 App과 Widget Extension에 설정하면 같은 파일 시스템 접근이 가능해집니다
    public static let appGroupId = "group.com.indextrown.Haruhancut.WidgetExtension"
    
    
    /// 사진을 저장할 폴더 URL을 만들어줍니다
    /// - Parameters:
    ///   - groupId: 사진 그룹 식별자
    ///   - dataKey: 날짜키
    /// - Returns: URL?
    public static func photosFolder(groupId: String, dateKey: String) -> URL? {
        // AppGroup 공유 폴더 위치를 가져옵니다
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            // 경로 추가
            .appendingPathComponent("Photos", isDirectory: true) // AppGroup/Photos/
            .appendingPathComponent(groupId, isDirectory: true)  // AppGroup/Photos/groupId/
            .appendingPathComponent(dateKey, isDirectory: true)  // AppGroup/Photos/groupId/2026-03-09/
    }
}
