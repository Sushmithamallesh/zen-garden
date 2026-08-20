import AppKit
import SwiftUI

final class ZenGardenAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = AppIconRenderer.make()
    }
}

@main
struct ZenGardenApp: App {
    @NSApplicationDelegateAdaptor(ZenGardenAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Zen Garden", id: "main") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 620)
        }
        .defaultSize(width: 980, height: 680)

        MenuBarExtra {
            MenuBarFocusView()
                .environmentObject(model)
        } label: {
            Label("Zen Garden", systemImage: model.settings.focusState().isActive ? "circle.inset.filled" : "circle.dotted")
        }
        .menuBarExtraStyle(.window)
    }
}
