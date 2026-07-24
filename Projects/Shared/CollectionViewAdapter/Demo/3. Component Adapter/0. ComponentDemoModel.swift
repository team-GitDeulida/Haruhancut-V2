import Foundation

/// Component 기반 예제에서 표시할 계좌 모델입니다.
struct ComponentDemoAccount: Hashable {
    /// Diffable item의 안정적인 식별자입니다.
    let id: String

    /// 계좌 이름입니다.
    let name: String

    /// 화면에 표시할 잔액 문자열입니다.
    let balanceText: String

    /// 왼쪽에 표시할 SF Symbols 이름입니다.
    let symbolName: String
}

extension ComponentDemoAccount {
    /// 예제 화면에서 사용할 계좌 목록입니다.
    static let sample: [Self] = [
        Self(
            id: "daily",
            name: "생활비 통장",
            balanceText: "2,450,000원",
            symbolName: "creditcard.fill"
        ),
        Self(
            id: "salary",
            name: "월급 통장",
            balanceText: "5,120,000원",
            symbolName: "banknote.fill"
        ),
        Self(
            id: "travel",
            name: "여행 적금",
            balanceText: "1,800,000원",
            symbolName: "airplane"
        ),
    ]
}
