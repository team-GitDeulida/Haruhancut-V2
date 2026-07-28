import SwiftUI

@main
struct CollectionViewAdapterDemoApp: App {
    private var readmeCapture:
        ReadmeCaptureRoute? {
        let arguments =
            ProcessInfo.processInfo.arguments
        guard
            let flagIndex = arguments.firstIndex(
                of: "--readme-capture"
            ),
            arguments.indices.contains(
                flagIndex + 1
            )
        else {
            return nil
        }

        return ReadmeCaptureRoute(
            rawValue: arguments[flagIndex + 1]
        )
    }

    @ViewBuilder
    private var rootView: some View {
        if let readmeCapture {
            ReadmeCaptureRootView(
                route: readmeCapture
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
