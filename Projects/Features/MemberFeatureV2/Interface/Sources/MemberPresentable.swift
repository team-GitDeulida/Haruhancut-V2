import Core
import Domain
import UIKit

/// Member 화면에서 Coordinator로 전달하는 이동 이벤트입니다.
public protocol MemberRouteTrigger {
    /// 프로필 이미지가 선택되었을 때 이미지 URL을 전달합니다.
    var onCellImageTapped:
        ((String) -> Void)? { get set }
}

/// Member 화면의 ViewModel 공개 계약입니다.
public typealias MemberViewModelType =
    ViewModelType & MemberRouteTrigger

/// Member 화면과 ViewModel을 함께 반환하는 Builder 결과입니다.
public typealias MemberPresentable = (
    vc: UIViewController,
    vm: any MemberViewModelType
)
