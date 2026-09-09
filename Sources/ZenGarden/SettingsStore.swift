import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var websites: [BlockedWebsite]
    @Published private(set) var schedules: [FocusSchedule]
    @Published private(set) var manualSessionStartedAt: Date?
    @Published private(set) var manualSessionEndsAt: Date?
    @Published private(set) var breakRecords: [BreakRecord]
    @Published private(set) var dailyFocusEnabled: Bool
    @Published private(set) var dailyStartMinute: Int
    @Published private(set) var dailyCutoffMinute: Int
    @Published private(set) var digestEnabled: Bool
    @Published private(set) var digestEmail: String
    @Published private(set) var lastDigestDay: String?
    @Published private(set) var sentDigestDays: Set<String>

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let websites = "zenGarden.websites.v1"
        static let schedules = "zenGarden.schedules.v1"
        static let manualSessionStartedAt = "zenGarden.manualSessionStartedAt.v1"
        static let manualSessionEndsAt = "zenGarden.manualSessionEndsAt.v1"
        static let legacyPausedUntil = "zenGarden.pausedUntil.v1"
        static let breakRecords = "zenGarden.breakRecords.v1"
        static let dailyFocusEnabled = "zenGarden.dailyFocusEnabled.v1"
        static let dailyStartMinute = "zenGarden.dailyStartMinute.v1"
        static let dailyCutoffMinute = "zenGarden.dailyCutoffMinute.v1"
        static let digestEnabled = "zenGarden.digestEnabled.v1"
        static let digestEmail = "zenGarden.digestEmail.v1"
        static let lastDigestDay = "zenGarden.lastDigestDay.v1"
        static let sentDigestDays = "zenGarden.sentDigestDays.v2"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Key.websites),
           let decoded = try? decoder.decode([BlockedWebsite].self, from: data) {
            websites = decoded
        } else {
            websites = [
                BlockedWebsite(domain: "instagram.com"),
                BlockedWebsite(domain: "reddit.com"),
                BlockedWebsite(domain: "x.com"),
                BlockedWebsite(domain: "tiktok.com"),
                BlockedWebsite(domain: "youtube.com")
            ]
        }

        if let data = defaults.data(forKey: Key.schedules),
           let decoded = try? decoder.decode([FocusSchedule].self, from: data) {
            schedules = decoded
        } else {
            schedules = [.workday]
        }

        if let data = defaults.data(forKey: Key.breakRecords),
           let decoded = try? decoder.decode([BreakRecord].self, from: data) {
            breakRecords = decoded
        } else {
            breakRecords = []
        }

        manualSessionStartedAt = defaults.object(forKey: Key.manualSessionStartedAt) as? Date
        manualSessionEndsAt = defaults.object(forKey: Key.manualSessionEndsAt) as? Date
        dailyFocusEnabled = defaults.object(forKey: Key.dailyFocusEnabled) as? Bool ?? true
        dailyStartMinute = defaults.object(forKey: Key.dailyStartMinute) as? Int
            ?? DailyFocusPolicy.defaultStartMinute
        dailyCutoffMinute = defaults.object(forKey: Key.dailyCutoffMinute) as? Int
            ?? DailyFocusPolicy.defaultCutoffMinute
        digestEnabled = defaults.object(forKey: Key.digestEnabled) as? Bool ?? true
        digestEmail = defaults.string(forKey: Key.digestEmail) ?? ""
        let storedLastDigestDay = defaults.string(forKey: Key.lastDigestDay)
        lastDigestDay = storedLastDigestDay
        if let data = defaults.data(forKey: Key.sentDigestDays),
           let decoded = try? decoder.decode(Set<String>.self, from: data) {
            sentDigestDays = decoded
        } else if let storedLastDigestDay {
            sentDigestDays = [storedLastDigestDay]
        } else {
            sentDigestDays = []
        }

        // Version one allowed an unaccounted global pause. It is intentionally
        // retired now that every exception requires a reason.
        defaults.removeObject(forKey: Key.legacyPausedUntil)
        performMaintenance(at: Date())
    }

    func focusState(at date: Date = Date(), calendar: Calendar = .current) -> FocusState {
        var candidates: [(source: FocusSource, end: Date)] = []

        if (dailyFocusEnabled || SundayLockPolicy.isActive(at: date, calendar: calendar)),
           let daily = DailyFocusPolicy.activeInterval(
               containing: date,
               startMinute: dailyStartMinute,
               cutoffMinute: dailyCutoffMinute,
               calendar: calendar
           ) {
            candidates.append((.daily, daily.end))
        }

        if let manualEnd = manualSessionEndsAt, manualEnd > date {
            candidates.append((.manual, manualEnd))
        }

        for schedule in schedules {
            if let interval = schedule.activeInterval(containing: date, calendar: calendar) {
                candidates.append((.schedule(schedule.name), interval.end))
            }
        }

        guard let active = candidates.max(by: { $0.end < $1.end }) else {
            return .inactive
        }

        return FocusState(
            isActive: true,
            source: active.source,
            endsAt: active.end
        )
    }

    func startSession(minutes: Int, now: Date = Date()) {
        let safeMinutes = min(max(minutes, 1), 12 * 60)
        manualSessionStartedAt = now
        manualSessionEndsAt = Calendar.current.date(byAdding: .minute, value: safeMinutes, to: now)
        persistSession()
    }

    func endManualSession() {
        manualSessionStartedAt = nil
        manualSessionEndsAt = nil
        persistSession()
    }

    @discardableResult
    func requestBreak(
        domain input: String,
        reason: String,
        minutes: Int,
        now: Date = Date()
    ) -> Bool {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let focus = focusState(at: now)
        guard !trimmedReason.isEmpty,
              focus.isActive,
              let domain = DomainMatcher.normalizedDomain(from: input),
              !isDomainLocked(domain, at: now),
              websites.contains(where: { $0.isEnabled && $0.domain == domain }),
              !isDomainTemporarilyAllowed(domain, at: now),
              let requestedEnd = Calendar.current.date(
                  byAdding: .minute,
                  value: min(max(minutes, 1), 120),
                  to: now
              )
        else { return false }
        let end = min(requestedEnd, focus.endsAt ?? requestedEnd)
        guard end > now else { return false }

        breakRecords.append(
            BreakRecord(
                domain: domain,
                reason: trimmedReason,
                requestedAt: now,
                scheduledEnd: end
            )
        )
        breakRecords.sort { $0.requestedAt > $1.requestedAt }
        persistBreakRecords()
        return true
    }

    func isDomainTemporarilyAllowed(_ domain: String, at date: Date = Date()) -> Bool {
        guard let normalized = DomainMatcher.normalizedDomain(from: domain) else { return false }
        return breakRecords.contains { record in
            record.domain == normalized && record.isActive(at: date)
        }
    }

    func activeBreaks(at date: Date = Date()) -> [BreakRecord] {
        breakRecords.filter { $0.isActive(at: date) }
    }

    func isDomainLocked(
        _ domain: String,
        at date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        SundayLockPolicy.isLocked(domain: domain, at: date, calendar: calendar)
    }

    func websitesForBlocking(
        at date: Date = Date(),
        calendar: Calendar = .current
    ) -> [BlockedWebsite] {
        var effectiveWebsites = websites
        guard SundayLockPolicy.isActive(at: date, calendar: calendar) else {
            return effectiveWebsites
        }

        for domain in SundayLockPolicy.domains {
            if let index = effectiveWebsites.firstIndex(where: { $0.domain == domain }) {
                effectiveWebsites[index].isEnabled = true
            } else {
                effectiveWebsites.append(BlockedWebsite(domain: domain))
            }
        }
        return effectiveWebsites
    }

    func availableBreakDomains(
        at date: Date = Date(),
        calendar: Calendar = .current
    ) -> [String] {
        websites
            .filter { $0.isEnabled && !isDomainLocked($0.domain, at: date, calendar: calendar) }
            .map(\.domain)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func endAllBreaks(at date: Date = Date()) {
        var changed = false
        for index in breakRecords.indices where breakRecords[index].isActive(at: date) {
            breakRecords[index].endedAt = date
            changed = true
        }
        if changed { persistBreakRecords() }
    }

    func breakRecords(on date: Date, calendar: Calendar = .current) -> [BreakRecord] {
        let interval = calendar.dateInterval(of: .day, for: date)
        return breakRecords
            .filter { record in
                guard let interval else { return false }
                return interval.contains(record.requestedAt)
            }
            .sorted { $0.requestedAt < $1.requestedAt }
    }

    func setDailyFocusEnabled(_ enabled: Bool) {
        dailyFocusEnabled = enabled
        defaults.set(enabled, forKey: Key.dailyFocusEnabled)
    }

    func setDailyStartMinute(_ minute: Int) {
        dailyStartMinute = min(max(minute, 0), (24 * 60) - 1)
        defaults.set(dailyStartMinute, forKey: Key.dailyStartMinute)
    }

    func setDailyCutoffMinute(_ minute: Int) {
        dailyCutoffMinute = min(max(minute, 0), (24 * 60) - 1)
        defaults.set(dailyCutoffMinute, forKey: Key.dailyCutoffMinute)
    }

    func setDigestEnabled(_ enabled: Bool) {
        digestEnabled = enabled
        defaults.set(enabled, forKey: Key.digestEnabled)
    }

    func setDigestEmail(_ email: String) {
        digestEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(digestEmail, forKey: Key.digestEmail)
    }

    func markDigestSent(for date: Date, calendar: Calendar = .current) {
        let key = Self.dayKey(for: date, calendar: calendar)
        lastDigestDay = key
        sentDigestDays.insert(key)
        defaults.set(lastDigestDay, forKey: Key.lastDigestDay)
        defaults.set(try? encoder.encode(sentDigestDays), forKey: Key.sentDigestDays)
    }

    func digestWasSent(for date: Date, calendar: Calendar = .current) -> Bool {
        sentDigestDays.contains(Self.dayKey(for: date, calendar: calendar))
    }

    func pendingDigestDate(at now: Date, calendar: Calendar = .current) -> Date? {
        var candidateDays: [Date] = []

        if let todayCutoff = dailyCutoff(on: now, calendar: calendar),
           now >= todayCutoff,
           !digestWasSent(for: now, calendar: calendar) {
            candidateDays.append(calendar.startOfDay(for: now))
        }

        for record in breakRecords {
            let recordDay = calendar.startOfDay(for: record.requestedAt)
            guard let cutoff = dailyCutoff(on: recordDay, calendar: calendar),
                  now >= cutoff,
                  !digestWasSent(for: recordDay, calendar: calendar)
            else { continue }
            candidateDays.append(recordDay)
        }

        return candidateDays.min()
    }

    func dailyCutoff(on date: Date, calendar: Calendar = .current) -> Date? {
        let dayStart = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .minute, value: dailyCutoffMinute, to: dayStart)
    }

    @discardableResult
    func addWebsite(_ input: String) -> Bool {
        guard let domain = DomainMatcher.normalizedDomain(from: input),
              !websites.contains(where: { $0.domain == domain })
        else { return false }

        websites.append(BlockedWebsite(domain: domain))
        websites.sort { $0.domain.localizedStandardCompare($1.domain) == .orderedAscending }
        persistWebsites()
        return true
    }

    func setWebsiteEnabled(id: UUID, isEnabled: Bool) {
        guard let index = websites.firstIndex(where: { $0.id == id }) else { return }
        websites[index].isEnabled = isEnabled
        persistWebsites()
    }

    func deleteWebsite(id: UUID) {
        websites.removeAll { $0.id == id }
        persistWebsites()
    }

    func addSchedule() {
        schedules.append(
            FocusSchedule(
                name: "New rhythm",
                startMinute: 9 * 60,
                endMinute: 12 * 60,
                weekdays: [2, 3, 4, 5, 6],
                isEnabled: true
            )
        )
        persistSchedules()
    }

    func updateSchedule(id: UUID, mutate: (inout FocusSchedule) -> Void) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }
        mutate(&schedules[index])
        persistSchedules()
    }

    func deleteSchedule(id: UUID) {
        schedules.removeAll { $0.id == id }
        persistSchedules()
    }

    func performMaintenance(at date: Date) {
        if let manualEnd = manualSessionEndsAt, manualEnd <= date {
            manualSessionStartedAt = nil
            manualSessionEndsAt = nil
            persistSession()
        }

        let retentionDate = Calendar.current.date(byAdding: .day, value: -90, to: date) ?? .distantPast
        let retained = breakRecords.filter { $0.requestedAt >= retentionDate }
        if retained.count != breakRecords.count {
            breakRecords = retained
            persistBreakRecords()
        }

        let retainedDayKeys = Set(breakRecords.map { Self.dayKey(for: $0.requestedAt, calendar: .current) })
        if let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: date) {
            let oldestKey = Self.dayKey(for: ninetyDaysAgo, calendar: .current)
            let pruned = sentDigestDays.filter { $0 >= oldestKey || retainedDayKeys.contains($0) }
            if pruned.count != sentDigestDays.count {
                sentDigestDays = Set(pruned)
                defaults.set(try? encoder.encode(sentDigestDays), forKey: Key.sentDigestDays)
            }
        }
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func persistWebsites() {
        defaults.set(try? encoder.encode(websites), forKey: Key.websites)
    }

    private func persistSchedules() {
        defaults.set(try? encoder.encode(schedules), forKey: Key.schedules)
    }

    private func persistSession() {
        defaults.set(manualSessionStartedAt, forKey: Key.manualSessionStartedAt)
        defaults.set(manualSessionEndsAt, forKey: Key.manualSessionEndsAt)
    }

    private func persistBreakRecords() {
        defaults.set(try? encoder.encode(breakRecords), forKey: Key.breakRecords)
    }
}
