import AppKit
import SwiftUI

@MainActor
final class ZenGardenAppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make the app an accessory process explicitly. `LSUIElement` handles
        // this at launch, but setting it here prevents a restored window scene
        // from changing the app's menu-bar-only behavior.
        NSApp.setActivationPolicy(.accessory)
        NSApp.applicationIconImage = AppIconRenderer.make()
        do {
            try LoginItemController.enableByDefaultIfNeeded()
            model.recordLaunchAtLoginError(nil)
        } catch {
            model.recordLaunchAtLoginError(error)
        }
        menuBarController = MenuBarController(model: model)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        menuBarController?.restoreStatusItem()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        // A menu-bar app has no Dock window to surface automatically. When a
        // user opens its .app again from Finder, make that action useful: put
        // the leaf back in the bar and show the dashboard as a reliable
        // fallback even if the status item was hidden by macOS.
        menuBarController?.restoreStatusItem()
        model.windowRouter.openMainWindow()
        return true
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

        Window("Today in Zen Garden", id: "end-of-day-review") {
            EndOfDayReviewView()
                .environmentObject(appDelegate.model)
                .frame(minWidth: 560, minHeight: 560)
        }
        .defaultSize(width: 600, height: 680)
        .windowResizability(.contentMinSize)
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
