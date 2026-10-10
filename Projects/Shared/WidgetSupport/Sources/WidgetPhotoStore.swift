//
//  WidgetPhotoStore.swift
//  WidgetSupport
//
//  Created by 김동현 on 3/9/26.
//

import Core
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

 // 위젯: 오늘 가장 늦게 저장한 사진
 WidgetPhotoStore.shared.latestPhotoData(
     groupId: "family",
     dateKey: Date().widgetDateKey()
 )
 */
/// 앱 또는 위젯에서 사용할 사진을 App Group 공유 폴더에 저장하는 저장소입니다
///
/// 사진은 `Photos/<groupId>/<dateKey>/<저장 시각>-<identifier>.jpg`에 저장합니다.
/// 파일 이름 규칙은 이 타입만 알고, 앱과 위젯은 아래 API로 읽고 씁니다.
public final class WidgetPhotoStore {

    /// 파일 이름 앞의 저장 시각(`yyyy-MM-dd-HH-mm-ss-`) 길이입니다
    private static let timestampPrefixLength = 20
    private static let fileExtension = ".jpg"

    private let storage: FileStorage?
    private let now: () -> Date

    /// - Parameters:
    ///   - storage: 사진을 저장할 저장소. 기본값은 위젯과 공유하는 App Group 저장소입니다.
    ///   - now: 저장 폴더와 파일 이름에 쓰는 현재 시각.
    public init(
        storage: FileStorage? = WidgetPaths.appGroupStorage(),
        now: @escaping () -> Date = Date.init
    ) {
        self.storage = storage
        self.now = now
    }
}

// MARK: - 기본 인스턴스
public extension WidgetPhotoStore {
    /// 위젯과 공유하는 App Group 저장소를 쓰는 기본 인스턴스입니다
    static let shared = WidgetPhotoStore()
}

// MARK: - 사진 저장·삭제·조회
public extension WidgetPhotoStore {
    func saveImage(data: Data,
                   groupId: String,
                   identifier: String
    ) throws {
        guard let storage else {
            throw WidgetPhotoError.invalidPath
        }

        let now = now()
        let dateKey = now.widgetDateKey()
        let timestamp = now.widgetTimestamp()
    
        // 2026-03-09-12-30-10-photo1.jpg
        let fileName = "\(timestamp)-\(identifier)\(Self.fileExtension)"
    
        // 파일 경로: Photos/family/2026-03-09/2026-03-09-12-30-10-photo1.jpg
        let path = WidgetPaths.photosDirectory(groupId: groupId, dateKey: dateKey)
            + "/" + fileName
    
        // 압축 & 리사이즈
        guard let downSampledImage = downsample(data: data, maxDimension: 800),
              let resized = downSampledImage.resized(to: CGSize(width: 200, height: 200)),
              let compressed = resized.jpegData(compressionQuality: 0.8)
        else {
            throw WidgetPhotoError.invalidImage
        }
    
        // 실제 파일 저장 (폴더가 없으면 만들고, 파일이 깨지지 않게 원자적으로 씁니다)
        try storage.write(compressed, to: path)
    
        print("[🟢] [WidgetPhotoStore] saved -> \(fileName)")
    }

    func deleteImage(groupId: String,
                     dateKey: String,
                     identifier: String
    ) {
        guard let storage else { return }
        let directory = WidgetPaths.photosDirectory(groupId: groupId, dateKey: dateKey)
    
        // identifier가 정확히 같은 파일 찾기 (끝부분만 같은 다른 사진은 지우지 않습니다)
        for fileName in photoFileNames(groupId: groupId, dateKey: dateKey)
        where Self.identifier(fromFileName: fileName) == identifier {
            // 파일 삭제
            storage.remove(directory + "/" + fileName)
            print("[🟢] [WidgetPhotoStore] deleted -> \(fileName)")
        }
    
        // 2026-03-09/ 제거
        if storage.contentsOfDirectory(directory).isEmpty {
            storage.remove(directory)
        }
    }

    /// 날짜 폴더에 저장된 사진의 식별자입니다. 저장 시각 순서입니다.
    func photoIdentifiers(groupId: String,
                          dateKey: String
    ) -> [String] {
        photoFileNames(groupId: groupId, dateKey: dateKey)
            .compactMap(Self.identifier(fromFileName:))
    }

    /// 날짜 폴더에서 가장 늦게 저장한 사진을 읽습니다.
    func latestPhotoData(groupId: String,
                         dateKey: String
    ) -> Data? {
        // 파일 이름이 저장 시각으로 시작하므로 이름순 마지막이 가장 최근입니다
        guard let latest = photoFileNames(groupId: groupId, dateKey: dateKey).last else {
            return nil
        }
        let directory = WidgetPaths.photosDirectory(groupId: groupId, dateKey: dateKey)
        return storage?.read(directory + "/" + latest)
    }

    /// 가장 최근 날짜 폴더에서 가장 늦게 저장한 사진을 읽습니다.
    func latestPhotoData(groupId: String) -> Data? {
        // 날짜 폴더 이름(yyyy-MM-dd)순 마지막이 가장 최근 날짜입니다
        guard let latestDateKey = storage?
            .contentsOfDirectory(WidgetPaths.photosDirectory(groupId: groupId))
            .sorted()
            .last
        else {
            return nil
        }
        return latestPhotoData(groupId: groupId, dateKey: latestDateKey)
    }
}

// MARK: - Private
private extension WidgetPhotoStore {
    /// 날짜 폴더의 사진 파일 이름을 저장 시각 순서로 정렬합니다.
    func photoFileNames(groupId: String, dateKey: String) -> [String] {
        let directory = WidgetPaths.photosDirectory(groupId: groupId, dateKey: dateKey)
        return (storage?.contentsOfDirectory(directory) ?? [])
            .filter { $0.hasSuffix(Self.fileExtension) }
            .sorted()
    }

    /// `<저장 시각>-<identifier>.jpg`에서 identifier를 읽습니다.
    static func identifier(fromFileName fileName: String) -> String? {
        guard fileName.count > timestampPrefixLength + fileExtension.count else {
            return nil
        }
        return String(
            fileName
                .dropFirst(timestampPrefixLength)
                .dropLast(fileExtension.count)
        )
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

import ImageIO

func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {

    let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false
    ]

    guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
        return nil
    }

    let downsampleOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension
    ]

    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
        source,
        0,
        downsampleOptions as CFDictionary
    ) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}
