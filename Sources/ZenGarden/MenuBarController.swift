import AppKit
import SwiftUI

/// Hosts the compact controls in a native popover anchored directly to the
/// status item. This avoids the large vertical placement offset produced by a
/// window-style SwiftUI `MenuBarExtra` on macOS 26.
@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover: NSPopover
    private let hostingController: NSHostingController<AnyView>
    private var globalMouseMonitor: Any?
    private var localKeyMonitor: Any?

    init(model: AppModel) {
        popover = NSPopover()
        hostingController = NSHostingController(rootView: AnyView(EmptyView()))

        super.init()

        hostingController.rootView = AnyView(
            MenuBarFocusView(onOpenDayReview: { [weak self, weak model] in
                self?.closePopover()
                model?.windowRouter.openEndOfDayReviewWindow()
            })
                .environmentObject(model)
        )

        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        installStatusItem()
        updatePopoverSize()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // Do not assign an autosave name. AppKit persists a named item's
        // placement and visibility, including a placement that macOS can no
        // longer render after the menu bar changes. Zen Garden has one
        // essential affordance, so each launch should request a fresh,
        // visible status item instead.
        item.isVisible = true

        if let button = item.button {
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

        statusItem = item
    }

    /// Restores the menu-bar affordance after Finder reopens the app or macOS
    /// has changed Spaces. The app delegate also calls this as a fallback for
    /// a menu-bar item that is no longer reachable by a click.
    func restoreStatusItem() {
        ensureStatusItemIsAvailable()
    }

    private func ensureStatusItemIsAvailable() {
        // A retained NSStatusItem is the supported AppKit ownership model.
        // Do not poll/recreate it: a status-button window can temporarily be
        // nil during Spaces and menu-bar transitions, and treating that as a
        // failure makes the icon flicker or disappear.
        guard statusItem.statusBar != nil, statusItem.button != nil else {
            installStatusItem()
            return
        }
        statusItem.isVisible = true
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
