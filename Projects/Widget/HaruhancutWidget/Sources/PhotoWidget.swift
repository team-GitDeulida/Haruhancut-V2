//
//  PhotoWidget.swift
//  HaruhancutWidget
//
//  Created by 김동현 on 3/9/26.
//

import WidgetKit
import SwiftUI
import WidgetSupport

// 1) Entry 모델: Widget에 표시할 데이터
struct PhotoWidgetModel: TimelineEntry {
    var date: Date
    let imageData: Data?
}

// 2) Provider: 타임라인 데이터를 공급하는 타입
struct PhotoWidgetProvider: TimelineProvider {
    // typealias Entry = <#type#>
    let appGroupID = "group.com.indextrown.Haruhancut.WidgetExtension"
    
    // 2-1) 위젯 갤러리나 로드 중에 보여줄 플레이스 홀더
    func placeholder(in context: Context) -> PhotoWidgetModel {
        return PhotoWidgetModel(date: Date(), imageData: nil)
    }
    
    // 2-2) 위젯 편집 화면 미리보기
    func getSnapshot(in context: Context, completion: @escaping (PhotoWidgetModel) -> Void) {
        let model = PhotoWidgetModel(date: Date(), imageData: nil)
        completion(model)
    }
    
    // 2-3) 실제 타임라인: 매일 자정(오전 0시 00분 05초)에 업데이트
    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotoWidgetModel>) -> Void) {
        let now = Date()
        
        let entry = PhotoWidgetModel(date: now,
                                     imageData: loadTodayImage())
        
        // 4) 다음 자정에 갱신
        let nextMidnight = computeNextMidnight(after: now)
        let timeLine = Timeline(entries: [entry],
                                policy: .after(nextMidnight))
        completion(timeLine)
    }
}

private extension PhotoWidgetProvider {
    func loadTodayImage() -> Data? {

        guard let user = WidgetSessionStore.loadUser(),
              let groupId = user.groupId else {
            print("❌ widget user 없음")
            return nil
        }

        guard let baseFolder = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("Photos", isDirectory: true)
            .appendingPathComponent(groupId, isDirectory: true)
        else {
            print("❌ widget baseFolder 없음")
            return nil
        }

        // 날짜 폴더만 가져오기
        let dateFolders = (try? FileManager.default.contentsOfDirectory(
            at: baseFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ))?.filter {
            (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        } ?? []

        guard let latestDateFolder = dateFolders.sorted(by: {
            $0.lastPathComponent > $1.lastPathComponent
        }).first else {
            print("❌ 날짜 폴더 없음")
            return nil
        }

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: latestDateFolder,
            includingPropertiesForKeys: nil
        ) else {
            print("❌ 이미지 없음")
            return nil
        }

        guard let latest = files.sorted(by: {
            $0.lastPathComponent > $1.lastPathComponent
        }).first else {
            print("❌ 최신 이미지 없음")
            return nil
        }

        print("✅ widget load image:", latest)

        return try? Data(contentsOf: latest)
    }
}

// widget view
struct PhotoWidgetView: View {

    var entry: PhotoWidgetProvider.Entry

    var body: some View {

        if let data = entry.imageData,
            // let image = downsampleImage(data: data, maxDimension: 600)
           let image = UIImage(data: data)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
                .widgetBackground(.clear)
        } else {
            
            Image("widgetPreview")
                .resizable()
                .scaledToFill()
                .clipped()
                .widgetBackground(.clear)
        }
    }
}

// widget 등록
struct PhotoWidget: Widget {

    let kind: String = "PhotoWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider: PhotoWidgetProvider()
        ) { entry in
            PhotoWidgetView(entry: entry)
        }
        .configurationDisplayName("하루한컷")
        .description("가족이 올린 오늘의 사진을 앱을 열지 않고도 확인할 수 있습니다.")
        .contentMarginsDisabled()
        .supportedFamilies([
            .systemSmall,
            .systemLarge
            // .systemMedium,
            // .accessoryCircular,
            // .accessoryRectangular,
            // .accessoryInline
            // systemMedium, systemLarge
        ])
    }
}


// MARK: - iOS17 이상일 경우 containerBackground를 17 미만일 경우에는 Background가 return
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                color
            }
        } else {
            return background(color)
        }
    }
}

// 3-2) 다음 자정(00:00:05) 시각을 계산하는 함수
private func computeNextMidnight(after date: Date) -> Date {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
    // 오늘 날짜 기준으로, 내일 00시 00분 05초
    comps.day! += 1
    comps.hour = 0
    comps.minute = 0
    comps.second = 5
    return Calendar.current.date(from: comps)!
}

//import ImageIO
func downsampleImage(data: Data, maxDimension: CGFloat) -> UIImage? {

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
