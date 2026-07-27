import Core
import Domain
import UIKit

/// 관리자 목록에서 Coordinator로 전달하는 이동 이벤트입니다.
public protocol AdminRouteTrigger {
    /// 선택한 그룹의 요약 정보를 전달합니다.
    var onGroupTapped:
        ((AdminGroupSummary) -> Void)?
    { get set }
}

/// 관리자 목록 ViewModel의 공개 계약입니다.
public typealias AdminViewModelType =
    ViewModelType & AdminRouteTrigger

/// 관리자 목록 화면과 ViewModel을 함께 반환합니다.
public typealias AdminPresentable = (
    vc: UIViewController,
    vm: any AdminViewModelType
)
