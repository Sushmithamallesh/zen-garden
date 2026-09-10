import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsStore
    let browserBlocker: BrowserBlocker

    private var cancellables: Set<AnyCancellable> = []
    private var maintenanceTimer: Timer?

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
        startMaintenance()
    }

    private func startMaintenance() {
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performMaintenance()
            }
        }
        timer.tolerance = 3
        RunLoop.main.add(timer, forMode: .common)
        maintenanceTimer = timer

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performMaintenance()
            }
        }

        performMaintenance()
    }

    private func performMaintenance(now: Date = Date()) {
        settings.performMaintenance(at: now)
    }
}

enum LoginItemController {
    private static let preferenceKey = "zenGarden.launchAtLoginEnabled.v1"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func enableByDefaultIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: preferenceKey) == nil else { return }
        try? setEnabled(true, defaults: defaults)
    }

    static func setEnabled(_ isEnabled: Bool, defaults: UserDefaults = .standard) throws {
        if isEnabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }

        defaults.set(isEnabled, forKey: preferenceKey)
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
