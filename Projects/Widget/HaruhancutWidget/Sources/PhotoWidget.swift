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
    /*
     오늘 사진 있음
     → todayFolder 존재
     → 이미지 표시
     
     오늘 사진 없음
     → todayFolder 없음 또는 파일 없음
     → nil 반환
     → placeholder 표시
     */
    func loadTodayImage() -> Data? {

        guard let user = WidgetSessionStore().loadUser(),
              let groupId = user.groupId else {
            print("❌ widget user 없음")
            return nil
        }

        guard let data = WidgetPhotoStore.shared.latestPhotoData(
            groupId: groupId,
            dateKey: Date().widgetDateKey()
        ) else {
            print("❌ 오늘 이미지 없음")
            return nil
        }

        return data
    }
    
    // legacy but useful
    func loadLatestImage() -> Data? {

        guard let user = WidgetSessionStore().loadUser(),
              let groupId = user.groupId else {
            print("❌ widget user 없음")
            return nil
        }

        guard let data = WidgetPhotoStore.shared.latestPhotoData(
            groupId: groupId
        ) else {
            print("❌ 최신 이미지 없음")
            return nil
        }

        return data
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
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                color
            }
        } else {
            background(color)
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
