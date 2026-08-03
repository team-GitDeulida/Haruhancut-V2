//
//  30. LongPressable.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// `LongPressable` UIView에 lazy하게 설치되는 내부 long press recognizer입니다.
///
/// recognizer가 이벤트 저장소도 함께 소유하며, 실제 long press가 시작된
/// 시점에 이벤트를 한 번 보냅니다. 하위 `UIControl`에서 시작한 터치는
/// 버튼과 스위치의 기본 동작에 맡깁니다.
@MainActor
private final class ComponentLongPressGestureRecognizer:
    UILongPressGestureRecognizer,
    UIGestureRecognizerDelegate
{
    let event = ComponentEvent<Void>()

    private weak var contentView: UIView?

    /// Content View의 long press만 전달할 recognizer를 만듭니다.
    ///
    /// - Parameter contentView: 제스처를 감지할 Component Content View.
    init(contentView: UIView) {
        self.contentView = contentView
        super.init(target: nil, action: nil)

        addTarget(self, action: #selector(didRecognizeLongPress))
        minimumPressDuration = 0.5
        cancelsTouchesInView = false
        delegate = self
    }

    /// Storyboard와 nib 기반 초기화는 지원하지 않습니다.
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    /// UIControl에서 시작한 터치를 제외하고 Content 내부 터치만 수신합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 수신 여부를 판단하는 long press recognizer.
    ///   - touch: 새로 시작된 터치.
    /// - Returns: Component 전체 long press로 처리할지 여부.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let contentView else {
            return false
        }

        return shouldReceiveComponentInteraction(
            touchedView: touch.view,
            within: contentView
        )
    }

    /// Scroll과 눌림 효과 recognizer가 long press와 함께 동작할 수 있는지 판단합니다.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 현재 long press recognizer.
    ///   - otherGestureRecognizer: 동시에 인식할지 판단할 상대 recognizer.
    /// - Returns: 두 recognizer의 동시 인식 허용 여부.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let longPressGestureRecognizer = otherGestureRecognizer as? UILongPressGestureRecognizer {
            // 0초 long press는 `Pressable`의 시각적 눌림 효과입니다.
            return longPressGestureRecognizer.minimumPressDuration == 0
        }

        return otherGestureRecognizer is UIPanGestureRecognizer
            && otherGestureRecognizer.view is UIScrollView
    }

    @objc
    /// Long press가 시작된 순간에만 구독자에게 이벤트를 전달합니다.
    private func didRecognizeLongPress() {
        guard state == .began else {
            return
        }

        event.send(())
    }
}

private extension UIView {
    /// UIView마다 하나만 설치되는 내부 long press recognizer를 반환합니다.
    var componentLongPressGestureRecognizer: ComponentLongPressGestureRecognizer {
        if let gestureRecognizer = gestureRecognizers?
            .compactMap({ $0 as? ComponentLongPressGestureRecognizer })
            .first {
            return gestureRecognizer
        }

        let gestureRecognizer = ComponentLongPressGestureRecognizer(contentView: self)
        addGestureRecognizer(gestureRecognizer)
        return gestureRecognizer
    }
}

/// Content 전체가 길게 누르기 동작을 지원함을 나타내는 capability입니다.
///
/// UIView Content는 프로토콜을 채택하는 것만으로 기본 long press 이벤트
/// 구현을 얻습니다. 이 프로토콜을 따르는 Content에만 `.onLongPress`
/// modifier가 노출됩니다.
@MainActor
public protocol LongPressable: AnyObject {
    /// Content를 길게 눌렀을 때 값을 보내는 이벤트입니다.
    var longPressEvent: ComponentEvent<Void> { get }
}

/// `LongPressable` UIView에 기본 long press 이벤트 구현을 제공합니다.
public extension LongPressable where Self: UIView {
    /// UIView 수명에 연결된 기본 long press 이벤트입니다.
    ///
    /// 이벤트를 소유한 recognizer는 처음 접근할 때 한 번만 설치됩니다.
    var longPressEvent: ComponentEvent<Void> {
        componentLongPressGestureRecognizer.event
    }
}

extension LongPressable where Self: UIView {
    /// 기본 long press recognizer를 설치하고 최신 인식 시간을 반영합니다.
    func installLongPressHandlingIfNeeded(minimumDuration: TimeInterval) {
        precondition(minimumDuration > 0, "minimumDuration은 0보다 커야 합니다.")

        isUserInteractionEnabled = true

        let gestureRecognizer = componentLongPressGestureRecognizer
        gestureRecognizer.minimumPressDuration = minimumDuration

        // Self-sizing으로 display 수명에서 빠졌다가 돌아온 Content도
        // UIKit의 현재 gesture environment에 다시 연결합니다.
        removeGestureRecognizer(gestureRecognizer)
        addGestureRecognizer(gestureRecognizer)
    }
}
