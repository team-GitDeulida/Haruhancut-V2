import SwiftUI

@main
struct CollectionViewAdapterDemoApp: App {
    private var readmeExample:
        READMEExampleRoute? {
        let arguments =
            ProcessInfo.processInfo.arguments
        guard
            let flagIndex = arguments.firstIndex(
                of: "--readme-example"
            ),
            arguments.indices.contains(
                flagIndex + 1
            )
        else {
            return nil
        }

        return READMEExampleRoute(
            rawValue: arguments[flagIndex + 1]
        )
    }

    @ViewBuilder
    private var rootView: some View {
        if let readmeExample {
            READMEExampleCaptureRootView(
                route: readmeExample
            )
        } else {
            RootListView()
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }
}
