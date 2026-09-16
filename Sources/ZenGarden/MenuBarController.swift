import AppKit
import SwiftUI

/// Hosts the compact controls in a native popover anchored directly to the
/// status item. This avoids the large vertical placement offset produced by a
/// window-style SwiftUI `MenuBarExtra` on macOS 26.
@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let hostingController: NSHostingController<AnyView>
    private var globalMouseMonitor: Any?
    private var localKeyMonitor: Any?

    init(model: AppModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        hostingController = NSHostingController(
            rootView: AnyView(
                MenuBarFocusView()
                    .environmentObject(model)
            )
        )

        super.init()

        if let button = statusItem.button {
            let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(
                systemSymbolName: "leaf.fill",
                accessibilityDescription: "Zen Garden"
            )?.withSymbolConfiguration(configuration)
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.toolTip = "Zen Garden"
            button.setAccessibilityLabel("Zen Garden")
            button.setAccessibilityHelp("Open focus controls")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        updatePopoverSize()
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        updatePopoverSize()
        popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func popoverDidShow(_ notification: Notification) {
        installDismissalMonitors()
    }

    func popoverDidClose(_ notification: Notification) {
        removeDismissalMonitors()
    }

    /// `.transient` handles normal clicks in the current app, but AppKit does
    /// not dismiss a transient popover when another status item opens a menu.
    /// A global mouse monitor covers that system-menu edge case without
    /// interfering with controls and menus inside this popover.
    private func installDismissalMonitors() {
        removeDismissalMonitors()

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopover()
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53, self?.popover.isShown == true else {
                return event
            }
            self?.closePopover()
            return nil
        }
    }

    private func removeDismissalMonitors() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }

    private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
    }

    private func updatePopoverSize() {
        let proposedSize = NSSize(width: 312, height: 720)
        let fittingSize = hostingController.sizeThatFits(in: proposedSize)
        popover.contentSize = NSSize(width: 312, height: ceil(fittingSize.height))
    }
}
