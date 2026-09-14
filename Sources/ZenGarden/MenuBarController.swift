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
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    private func updatePopoverSize() {
        let proposedSize = NSSize(width: 312, height: 720)
        let fittingSize = hostingController.sizeThatFits(in: proposedSize)
        popover.contentSize = NSSize(width: 312, height: ceil(fittingSize.height))
    }
}
