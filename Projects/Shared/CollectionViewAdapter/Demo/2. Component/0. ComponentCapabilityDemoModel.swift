import UIKit

/// Component capability 데모가 표시할 예제 종류입니다.
enum ComponentCapabilityDemoKind: String {
    case touchable
    case pressable
    case longPressable
    case containsButton
    case containsSwitch

    var title: String {
        switch self {
        case .touchable:
            "Touchable"
        case .pressable:
            "Pressable"
        case .longPressable:
            "LongPressable"
        case .containsButton:
            "ContainsButton"
        case .containsSwitch:
            "ContainsSwitch"
        }
    }

    var summary: String {
        switch self {
        case .touchable:
            "카드 전체를 탭하면 .onTouch에 전달한 closure가 실행됩니다."
        case .pressable:
            "카드를 누르는 동안 .pressedEffect가 Content를 축소합니다."
        case .longPressable:
            "카드를 길게 누르면 .onLongPress에 전달한 closure가 실행됩니다."
        case .containsButton:
            "카드 내부 버튼이 buttonTapEvent를 통해 동작을 전달합니다."
        case .containsSwitch:
            "카드 내부 UISwitch가 변경된 Bool 값을 전달합니다."
        }
    }

    var cardTitle: String {
        switch self {
        case .touchable:
            "카드 전체를 탭해 보세요"
        case .pressable:
            "카드를 길게 눌러 보세요"
        case .longPressable:
            "카드를 0.6초 동안 눌러 보세요"
        case .containsButton:
            "내부 버튼만 눌러 보세요"
        case .containsSwitch:
            "알림 설정을 바꿔 보세요"
        }
    }

    var cardDescription: String {
        switch self {
        case .touchable:
            "Content 전체가 하나의 상호작용 영역이 됩니다."
        case .pressable:
            "터치가 시작되면 94% 크기로 줄고 끝나면 복원됩니다."
        case .longPressable:
            "지정한 시간이 지나면 이벤트를 한 번 전달합니다."
        case .containsButton:
            "Content는 버튼 이벤트를 노출하고 동작은 Component가 연결합니다."
        case .containsSwitch:
            "UISwitch의 상태는 화면 상태로 반영되어 다시 렌더링됩니다."
        }
    }

    var code: String {
        switch self {
        case .touchable:
            ".onTouch { ... }"
        case .pressable:
            ".pressedEffect(scale: 0.94)"
        case .longPressable:
            ".onLongPress(minimumDuration: 0.6) { ... }"
        case .containsButton:
            ".onButtonTap { ... }"
        case .containsSwitch:
            ".onToggle { isOn in ... }"
        }
    }

    var symbolName: String {
        switch self {
        case .touchable:
            "hand.tap.fill"
        case .pressable:
            "arrow.down.to.line.compact"
        case .longPressable:
            "hand.point.up.left.fill"
        case .containsButton:
            "button.programmable"
        case .containsSwitch:
            "switch.2"
        }
    }

    var accentColor: UIColor {
        switch self {
        case .touchable:
            .systemBlue
        case .pressable:
            .systemIndigo
        case .longPressable:
            .systemPurple
        case .containsButton:
            .systemOrange
        case .containsSwitch:
            .systemGreen
        }
    }

    var initialResult: String {
        switch self {
        case .touchable:
            "아직 카드를 탭하지 않았습니다."
        case .pressable:
            "손가락을 올려 축소 효과를 확인해 보세요."
        case .longPressable:
            "아직 long press 이벤트를 받지 않았습니다."
        case .containsButton:
            "아직 내부 버튼을 누르지 않았습니다."
        case .containsSwitch:
            "알림이 켜져 있습니다."
        }
    }
}

/// 네 capability Component가 공통으로 표시하는 상태입니다.
struct ComponentCapabilityDemoItem:
    Identifiable,
    Equatable
{
    let kind: ComponentCapabilityDemoKind
    var isOn: Bool = true

    var id: String {
        kind.rawValue
    }
}
