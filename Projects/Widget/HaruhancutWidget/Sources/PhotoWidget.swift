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
        
        
    }
}
