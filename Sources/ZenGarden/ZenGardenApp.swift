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

        Window("Request a Break", id: "break-request") {
            BreakRequestWindow()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarFocusView()
                .environmentObject(model)
        } label: {
            ZenGardenMark(size: 18)
                .accessibilityLabel("Zen Garden")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct BreakRequestWindow: View {
    var body: some View {
        BreakRequestView(compact: false) {
            NSApp.keyWindow?.close()
        }
        .background(GardenTheme.warmWhite)
    }
}
