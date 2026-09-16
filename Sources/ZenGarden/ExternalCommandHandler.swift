import AppKit
import SwiftUI

private struct ExternalCommandHandler: ViewModifier {
    @EnvironmentObject private var model: AppModel

    func body(content: Content) -> some View {
        content.onOpenURL { url in
            guard url.scheme?.lowercased() == "zengarden" else { return }

            switch url.host?.lowercased() {
            case "request-break":
                model.windowRouter.openBreakRequestWindow()
            case "resume":
                model.settings.endAllBreaks()
            case "open":
                model.windowRouter.openMainWindow()
            default:
                break
            }
        }
    }
}

extension View {
    func handlesZenGardenCommands() -> some View {
        modifier(ExternalCommandHandler())
    }
}
