import AppKit
import SwiftUI

private struct ExternalCommandHandler: ViewModifier {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.onOpenURL { url in
            guard url.scheme?.lowercased() == "zengarden" else { return }

            switch url.host?.lowercased() {
            case "request-break":
                openWindow(id: "break-request")
                NSApp.activate(ignoringOtherApps: true)
            case "resume":
                model.settings.endAllBreaks()
            case "open":
                openWindow(id: "main")
                WindowController.showMainWindow()
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
