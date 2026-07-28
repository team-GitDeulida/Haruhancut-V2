import CollectionViewAdapter
import UIKit

/// `Touchable`만 채택한 Content를 만드는 Component입니다.
struct TouchableDemoComponent: Component {
    let item: ComponentCapabilityDemoItem

    var estimatedHeight: CGFloat {
        164
    }

    func createContent() -> TouchableDemoContentView {
        TouchableDemoContentView()
    }

    func render(
        context _: ComponentContext,
        content: TouchableDemoContentView
    ) {
        content.item = item
    }
}

/// `Pressable`만 채택한 Content를 만드는 Component입니다.
struct PressableDemoComponent: Component {
    let item: ComponentCapabilityDemoItem

    var estimatedHeight: CGFloat {
        164
    }

    func createContent() -> PressableDemoContentView {
        PressableDemoContentView()
    }

    func render(
        context _: ComponentContext,
        content: PressableDemoContentView
    ) {
        content.item = item
    }
}

/// `ContainsButton`만 채택한 Content를 만드는 Component입니다.
struct ContainsButtonDemoComponent: Component {
    let item: ComponentCapabilityDemoItem

    var estimatedHeight: CGFloat {
        164
    }

    func createContent() -> ContainsButtonDemoContentView {
        ContainsButtonDemoContentView()
    }

    func render(
        context _: ComponentContext,
        content: ContainsButtonDemoContentView
    ) {
        content.item = item
    }
}

/// `ContainsSwitch`만 채택한 Content를 만드는 Component입니다.
struct ContainsSwitchDemoComponent: Component {
    let item: ComponentCapabilityDemoItem

    var estimatedHeight: CGFloat {
        164
    }

    func createContent() -> ContainsSwitchDemoContentView {
        ContainsSwitchDemoContentView()
    }

    func render(
        context _: ComponentContext,
        content: ContainsSwitchDemoContentView
    ) {
        content.item = item
    }
}
