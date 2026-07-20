import SwiftUI
import UIKit

extension UIViewController {
    @MainActor
    func toSwiftUI() -> some View {
        UIViewControllerContainer(viewController: self)
    }
}

private struct UIViewControllerContainer<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController

    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }

    func updateUIViewController(
        _ uiViewController: ViewController,
        context: Context
    ) {}
}
