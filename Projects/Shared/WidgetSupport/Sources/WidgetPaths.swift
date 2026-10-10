//
//  WidgetPaths.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Core
import Foundation

public enum WidgetPaths {

    /// 앱과 위젯이 데이터를 공유하기 위한 App Group 식별자입니다
    /// 기본적으로 iOS 는App sandbox <-> Widget sandbox가 서로 분리되어 있어 파일 접근이 안됩니다
    /// Apple이 제공하는 공유 영역인 App Group을 App과 Widget Extension에 설정하면 같은 파일 시스템 접근이 가능해집니다
    public static let appGroupId = "group.com.indextrown.Haruhancut.WidgetExtension"

    /// 앱과 위젯이 함께 쓰는 App Group 파일 저장소를 만듭니다.
    ///
    /// - Returns: App Group 권한이 없는 타깃에서는 `nil`.
    public static func appGroupStorage() -> FileStorage? {
        FileStorage(location: .appGroup(appGroupId))
    }

    /// 그룹의 날짜 폴더들을 담는 상대 경로입니다. (예: `Photos/family`)
    static func photosDirectory(groupId: String) -> String {
        "Photos/\(groupId)"
    }

    /// 사진을 저장할 날짜 폴더의 상대 경로입니다. (예: `Photos/family/2026-03-09`)
    /// - Parameters:
    ///   - groupId: 사진 그룹 식별자
    ///   - dateKey: 날짜키
    static func photosDirectory(groupId: String, dateKey: String) -> String {
        photosDirectory(groupId: groupId) + "/" + dateKey
    }

    /// 위젯용 사용자 정보를 저장할 파일의 상대 경로입니다.
    static let sessionFile = "Session/user.json"
}
