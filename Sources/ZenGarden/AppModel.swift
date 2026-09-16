import AppKit
import Combine
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class WindowRouter {
    private var openWindowAction: OpenWindowAction?
    private var pendingWindowID: String?

    func register(_ action: OpenWindowAction) {
        openWindowAction = action

        if let pendingWindowID {
            self.pendingWindowID = nil
            openWindow(id: pendingWindowID)
        }
    }

    func openMainWindow() {
        openWindow(id: "main")
    }

    func openBreakRequestWindow() {
        openWindow(id: "break-request")
    }

    private func openWindow(id: String) {
        guard let openWindowAction else {
            pendingWindowID = id
            WindowController.raiseExistingWindow(withTitle: title(for: id))
            return
        }

        openWindowAction(id: id)
        // `openWindow` creates a destroyed SwiftUI window asynchronously. Raise
        // it on the next run loop once AppKit has attached the NSWindow.
        DispatchQueue.main.async {
            WindowController.raiseExistingWindow(withTitle: self.title(for: id))
        }
    }

    private func title(for id: String) -> String {
        id == "break-request" ? "Unblock a Website" : "Zen Garden"
    }
}

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsStore
    let browserBlocker: BrowserBlocker
    let windowRouter = WindowRouter()

    @Published private(set) var launchAtLoginError: String?

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
                    await Task.yield()
                    await self?.browserBlocker.checkNow()
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
        Task { [weak self] in
            await self?.browserBlocker.checkNow()
        }
    }

    func recordLaunchAtLoginError(_ error: Error?) {
        launchAtLoginError = error?.localizedDescription
    }
}

enum LoginItemController {
    private static let preferenceKey = "zenGarden.launchAtLoginEnabled.v1"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func enableByDefaultIfNeeded(defaults: UserDefaults = .standard) throws {
        guard defaults.object(forKey: preferenceKey) == nil else { return }
        try setEnabled(true, defaults: defaults)
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
    static func raiseExistingWindow(withTitle title: String) {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.title == title }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
