import AppKit
import SwiftUI

@MainActor
final class ZenGardenAppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = AppIconRenderer.make()
        LoginItemController.enableByDefaultIfNeeded()
        menuBarController = MenuBarController(model: model)
    }
}

@main
struct ZenGardenApp: App {
    @NSApplicationDelegateAdaptor(ZenGardenAppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Zen Garden", id: "main") {
            RootView()
                .environmentObject(appDelegate.model)
                .frame(minWidth: 900, minHeight: 620)
        }
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(replacing: .appTermination) {
                EmptyView()
            }
        }

        Window("Unblock a Website", id: "break-request") {
            BreakRequestWindow()
                .environmentObject(appDelegate.model)
        }
        .windowResizability(.contentSize)
    }
}

private struct BreakRequestWindow: View {
    var body: some View {
        BreakRequestView(compact: false) {
            NSApp.keyWindow?.close()
        }
        .background(GardenTheme.warmWhite)
        .handlesZenGardenCommands()
    }
}
