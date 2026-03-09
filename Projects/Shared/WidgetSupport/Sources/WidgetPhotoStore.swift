//
//  WidgetPhotoStore.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Foundation

/*
 [사용법]
 WidgetPhotoStore.shared.saveImage(
     data: imageData,
     groupId: "family",
     identifier: "photo1"
 )
 */
/// 앱 또는 위젯에서 사용할 사진을 App Group 공유 폴더에 저장하는 유틸 싱글톤입니다
public final class WidgetPhotoStore {
    
    // 싱글톤
    /// 파일 시스템 접근 관리
    /// AppGroup 공유 리소스
    public static let shared = WidgetPhotoStore()
    private init() {}
    
    public func saveImage(data: Data,
                          groupId: String,
                          identifier: String
    ) throws {
        let now = Date()
        let dateKey = now.widgetDateKey()
        let timestamp = now.widgetTimestamp()
        
        // 2026-03-09-12-30-10-photo1.jpg
        let fileName = "\(timestamp)-\(identifier).jpg"
        
        // 저장 폴더 경로 생성
        // AppGroup/Photos/groupId/2026-03-09/
        guard let folder = WidgetPaths.photosFolder(groupId: groupId,
                                                    dateKey: dateKey
        ) else {
            throw WidgetPhotoError.invalidPath
        }
        
        // 폴더가 없으면 생성
        // withIntermediateDirectories: 중간 폴더도 자동 생성
        try FileManager.default.createDirectory(at: folder,
                                                withIntermediateDirectories: true)
        // 파일 경로: Photos/family/2026-03-09/2026-03-09-12-30-10-photo1.jpg
        let fileURL = folder.appendingPathComponent(fileName)
        
        // 실제 파일 저장
        // atomic(파일깨짐방지)
        // - 임시파일 작성
        // - 임시파일 작성
        try data.write(to: fileURL, options: .atomic)
    }
}
