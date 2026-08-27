import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsStore
    let browserBlocker: BrowserBlocker
    @Published private(set) var digestStatus = "Add an email address to enable the daily email."
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
        refreshDigestStatus()

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

    func refreshDigestStatus(now: Date = Date()) {
        if !settings.digestEnabled {
            digestStatus = "Daily email is off."
        } else if settings.digestEmail.isEmpty {
            digestStatus = "Add an email address."
        } else if settings.digestWasSent(for: now) {
            digestStatus = "Today’s email was sent."
        } else if let pendingDate = settings.pendingDigestDate(at: now) {
            digestStatus = Calendar.current.isDate(pendingDate, inSameDayAs: now)
                ? "Today’s email is pending."
                : "A missed email is pending."
        } else if let cutoff = settings.dailyCutoff(on: now) {
            digestStatus = "Next email: \(cutoff.formatted(date: .omitted, time: .shortened))."
        }
    }

    private func startMaintenance() {
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performMaintenance()
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
              let digestDate = settings.pendingDigestDate(at: now)
        else { return }

        if let lastAutomaticDigestAttempt,
           now.timeIntervalSince(lastAutomaticDigestAttempt) < 5 * 60 {
            return
        }
        lastAutomaticDigestAttempt = now
        await sendDigest(for: digestDate, automatic: true)
    }

    private func sendDigest(for date: Date, automatic: Bool) async {
        guard !isSendingDigest else { return }

        let recipient = settings.digestEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.looksLikeEmail(recipient) else {
            digestStatus = "Add a valid email address before sending a digest."
            return
        }

        isSendingDigest = true
        digestStatus = "Sending through Apple Mail…"
        let records = settings.breakRecords(on: date)
        let sentAt = Date()
        let subject = "Zen Garden · \(Self.subjectDateFormatter.string(from: date))"
        let body = Self.digestBody(records: records, date: date, asOf: sentAt)

        do {
            try await digestMailer.send(to: recipient, subject: subject, body: body)
            let isPastCutoff = settings.dailyCutoff(on: date).map { sentAt >= $0 } ?? false
            if automatic || isPastCutoff {
                settings.markDigestSent(for: date)
                digestStatus = "Today’s email was sent."
            } else {
                digestStatus = "Email sent. The scheduled email will still send at the cutoff."
            }
        } catch {
            digestStatus = "Could not send: \(error.localizedDescription)"
        }
        isSendingDigest = false
    }

    private static func looksLikeEmail(_ value: String) -> Bool {
        value.range(
            of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
            options: .regularExpression
        ) != nil
    }

    private static func digestBody(records: [BreakRecord], date: Date, asOf sentAt: Date) -> String {
        var lines = [
            "ZEN GARDEN · ACCESS SUMMARY",
            subjectDateFormatter.string(from: date),
            ""
        ]

        if records.isEmpty {
            lines.append("No breaks were requested today.")
        } else {
            lines.append(records.count == 1 ? "1 temporary access request" : "\(records.count) temporary access requests")
            lines.append("")

            for record in records {
                let actualMinutes = max(1, Int(ceil(record.activeDuration(until: sentAt) / 60)))
                lines.append("\(timeFormatter.string(from: record.requestedAt)) · \(record.domain) · \(actualMinutes) min")
                lines.append(record.reason)
                lines.append("")
            }
        }

        lines.append("Generated locally by Zen Garden.")
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
