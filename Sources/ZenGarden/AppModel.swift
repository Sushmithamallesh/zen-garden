import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsStore
    let browserBlocker: BrowserBlocker
    @Published private(set) var digestStatus = "Daily digest is waiting for an email address."
    @Published private(set) var isSendingDigest = false

    private var cancellables: Set<AnyCancellable> = []
    private let digestMailer = DailyDigestMailer()
    private var maintenanceTimer: Timer?
    private var lastAutomaticDigestAttempt: Date?

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

    func sendTodayDigest() async {
        await sendDigest(for: Date(), automatic: false)
    }

    private func startMaintenance() {
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performMaintenance()
            }
        }
        maintenanceTimer?.tolerance = 3

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performMaintenance()
            }
        }

        Task {
            await performMaintenance()
        }
    }

    private func performMaintenance(now: Date = Date()) async {
        settings.performMaintenance(at: now)
        guard settings.digestEnabled,
              !settings.digestEmail.isEmpty,
              let cutoff = settings.dailyCutoff(on: now),
              now >= cutoff,
              !settings.digestWasSent(for: now)
        else { return }

        if let lastAutomaticDigestAttempt,
           now.timeIntervalSince(lastAutomaticDigestAttempt) < 5 * 60 {
            return
        }
        lastAutomaticDigestAttempt = now
        await sendDigest(for: now, automatic: true)
    }

    private func sendDigest(for date: Date, automatic: Bool) async {
        guard !isSendingDigest else { return }

        let recipient = settings.digestEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.looksLikeEmail(recipient) else {
            digestStatus = "Add a valid email address before sending a digest."
            return
        }

        isSendingDigest = true
        digestStatus = "Sending today’s reflection through Apple Mail…"
        let records = settings.breakRecords(on: date)
        let subject = "Zen Garden · \(Self.subjectDateFormatter.string(from: date))"
        let body = Self.digestBody(records: records, date: date)

        do {
            try await digestMailer.send(to: recipient, subject: subject, body: body)
            let isPastCutoff = settings.dailyCutoff(on: date).map { date >= $0 } ?? false
            if automatic || isPastCutoff {
                settings.markDigestSent(for: date)
                digestStatus = "Today’s reflection was sent through Apple Mail."
            } else {
                digestStatus = "Preview sent. The final reflection will still send at the cutoff."
            }
        } catch {
            digestStatus = "Could not send: \(error.localizedDescription)"
        }
        isSendingDigest = false
    }

    private static func looksLikeEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && parts[1].contains(".")
    }

    private static func digestBody(records: [BreakRecord], date: Date) -> String {
        var lines = [
            "ZEN GARDEN · DAILY REFLECTION",
            subjectDateFormatter.string(from: date),
            ""
        ]

        if records.isEmpty {
            lines.append("No breaks were requested today.")
        } else {
            lines.append(records.count == 1 ? "1 deliberate break" : "\(records.count) deliberate breaks")
            lines.append("")

            for record in records {
                let requestedMinutes = max(1, Int(record.scheduledEnd.timeIntervalSince(record.requestedAt) / 60))
                lines.append("\(timeFormatter.string(from: record.requestedAt)) · \(record.domain) · \(requestedMinutes) min")
                lines.append(record.reason)
                lines.append("")
            }
        }

        lines.append("Notice the pattern without judging it. Tomorrow is another garden.")
        lines.append("")
        lines.append("Sent privately from Zen Garden on your Mac.")
        return lines.joined(separator: "\n")
    }

    private static let subjectDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
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
