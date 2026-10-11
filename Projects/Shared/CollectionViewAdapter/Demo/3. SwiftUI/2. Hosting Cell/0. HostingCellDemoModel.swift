import Foundation

/// SwiftUI 셀 Demo의 설정 행입니다.
struct HostingCellDemoRow: Identifiable, Equatable {
    let id: String
    let symbolName: String
    let title: String
    let description: String
    var isOn: Bool
}

/// SwiftUI 셀 Demo의 사진 카드입니다.
struct HostingCellDemoPhoto: Identifiable, Equatable {
    let id: Int
    var isFavorite: Bool

    var imageURL: URL? {
        URL(string: "https://picsum.photos/seed/haruhancut-hosting-\(id)/600/400")
    }
}

/// Section header에 표시할 제목입니다.
struct HostingCellDemoHeader: Identifiable, Equatable {
    let id: String
    let title: String
    let caption: String
}

extension HostingCellDemoRow {
    static let samples: [HostingCellDemoRow] = [
        .init(
            id: "notification",
            symbolName: "bell.fill",
            title: "알림",
            description: "가족이 사진을 올리면 알려 줍니다.",
            isOn: true
        ),
        .init(
            id: "widget",
            symbolName: "square.grid.2x2.fill",
            title: "홈 화면 위젯",
            description: "오늘 가장 최근에 올라온 사진을 홈 화면 위젯에 보여 줍니다. 설명이 길면 여러 줄로 감싸지고, 셀 높이도 SwiftUI가 계산한 만큼 늘어납니다.",
            isOn: false
        ),
        .init(
            id: "birthday",
            symbolName: "gift.fill",
            title: "생일",
            description: "가족 생일 전날 알려 줍니다.",
            isOn: true
        ),
        .init(
            id: "backup",
            symbolName: "icloud.fill",
            title: "사진 백업",
            description: "올린 사진을 원본 크기로 보관합니다. 셀을 누르면 Item이 바뀌어 바뀐 행만 다시 그려집니다.",
            isOn: false
        ),
    ]
}
