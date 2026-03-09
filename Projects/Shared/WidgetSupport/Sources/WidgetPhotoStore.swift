//
//  WidgetPhotoStore.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Foundation
import UIKit

/*
 [사용법]
 WidgetPhotoStore.shared.saveImage(
     data: imageData,
     groupId: "family",
     identifier: "photo1"
 )
 
 WidgetPhotoStore.shared.deleteImage(
     groupId: "family",
     dateKey: Date().widgetDateKey(),
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
        
        // 압축 & 리사이즈
        guard let image = UIImage(data: data),
              let resized = image.resized(to: CGSize(width: 200, height: 200)),
              let compressed = resized.jpegData(compressionQuality: 0.8)
        else {
            throw WidgetPhotoError.invalidImage
        }
        
        // 실제 파일 저장
        // atomic(파일깨짐방지)
        // - 임시파일 작성
        // - 임시파일 작성
        try compressed.write(to: fileURL, options: .atomic)
        
        print("✅ [WidgetPhotoStore] saved -> \(fileURL.path)")
    }
    
    public func deleteImage(groupId: String,
                            dateKey: String,
                            identifier: String
    ) {
        // 폴더 찾기
        guard let folder = WidgetPaths.photosFolder(groupId: groupId,
                                                    dateKey: dateKey
        ) else {
            return
        }
        
        // 폴더 안 파일 목록 가져오기
        guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil
        ) else {
            return
        }
        
        // identifier 포함 파일 찾기
        for file in files where file.lastPathComponent.hasSuffix("\(identifier).jpg") {
            // 파일 삭제
            try? FileManager.default.removeItem(at: file)
            print("✅ [WidgetPhotoStore] deleted -> \(file.lastPathComponent)")
        }
        
        // 2026-03-09/ 제거
        if let remain = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        ),
        remain.isEmpty {
            try? FileManager.default.removeItem(at: folder)
        }
    }
}

/*
 
 ✅ [WidgetPhotoStore] saved -> /Users/kimdonghyeon/Library/Developer/CoreSimulator/Devices/C9B00839-D844-4310-A11F-BB101B54BF23/data/Containers/Shared/AppGroup/DC7BC3F4-0612-43BC-8376-13B54904C386/Photos/-OmtewEFRElL3TAKUDMB/2026-03-09/2026-03-09-15-30-31-DC9AEE45-0D81-474A-A55E-FBBD1B3FEFCB.jpg
 
 ✅ [WidgetPhotoStore] deleted -> 2026-03-09-15-30-31-DC9AEE45-0D81-474A-A55E-FBBD1B3FEFCB.jpg
 */

extension UIImage {

    func resized(to size: CGSize) -> UIImage? {

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
