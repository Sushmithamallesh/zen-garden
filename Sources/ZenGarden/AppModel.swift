import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsStore
    let browserBlocker: BrowserBlocker
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let settings = SettingsStore()
        let browserBlocker = BrowserBlocker()
        self.settings = settings
        self.browserBlocker = browserBlocker

        settings.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        browserBlocker.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        browserBlocker.start(settings: settings)
    }
}

enum LoginItemController {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}

@MainActor
enum WindowController {
    static func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.title.contains("Zen Garden") }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
        }
    }
}
