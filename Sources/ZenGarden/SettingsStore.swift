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
    }

    private static let retiredEmailPreferenceKeys = [
        "zenGarden.digestEnabled.v1",
        "zenGarden.digestEmail.v1",
        "zenGarden.lastDigestDay.v1",
        "zenGarden.sentDigestDays.v2"
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Key.websites),
           let decoded = try? decoder.decode([BlockedWebsite].self, from: data) {
            websites = Self.sanitizedWebsites(decoded)
        } else {
            websites = Self.defaultWebsites
        }

        if let data = defaults.data(forKey: Key.schedules),
           let decoded = try? decoder.decode([FocusSchedule].self, from: data) {
            schedules = Self.sanitizedSchedules(decoded)
        } else {
            schedules = [.workday]
        }

        if let data = defaults.data(forKey: Key.breakRecords),
           let decoded = try? decoder.decode([BreakRecord].self, from: data) {
            breakRecords = Self.sanitizedBreakRecords(decoded)
        } else {
            breakRecords = []
        }

        manualSessionStartedAt = defaults.object(forKey: Key.manualSessionStartedAt) as? Date
        manualSessionEndsAt = defaults.object(forKey: Key.manualSessionEndsAt) as? Date
        dailyFocusEnabled = defaults.object(forKey: Key.dailyFocusEnabled) as? Bool ?? true
        dailyStartMinute = Self.validMinute(
            defaults.object(forKey: Key.dailyStartMinute) as? Int
                ?? DailyFocusPolicy.defaultStartMinute
        )
        dailyCutoffMinute = Self.validMinute(
            defaults.object(forKey: Key.dailyCutoffMinute) as? Int
                ?? DailyFocusPolicy.defaultCutoffMinute
        )

        // Version one allowed an unaccounted global pause. It is intentionally
        // retired now that every exception requires a reason.
        defaults.removeObject(forKey: Key.legacyPausedUntil)
        Self.retiredEmailPreferenceKeys.forEach { defaults.removeObject(forKey: $0) }
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

    func endManualSession(at date: Date = Date()) {
        manualSessionStartedAt = nil
        manualSessionEndsAt = nil
        persistSession()
        endAllBreaks(at: date)
    }

    @discardableResult
    func requestBreak(
        domain input: String,
        reason: String,
        minutes: Int,
        now: Date = Date()
    ) -> Bool {
        let focus = focusState(at: now)
        guard focus.isActive,
              let normalizedReason = TemporaryAccessPolicy.normalizedReason(reason),
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
                reason: normalizedReason,
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
        endAllBreaks()
    }

    func setDailyStartMinute(_ minute: Int) {
        dailyStartMinute = min(max(minute, 0), (24 * 60) - 1)
        defaults.set(dailyStartMinute, forKey: Key.dailyStartMinute)
        endAllBreaks()
    }

    func setDailyCutoffMinute(_ minute: Int) {
        dailyCutoffMinute = min(max(minute, 0), (24 * 60) - 1)
        defaults.set(dailyCutoffMinute, forKey: Key.dailyCutoffMinute)
        endAllBreaks()
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

    func setWebsiteEnabled(id: UUID, isEnabled: Bool, at date: Date = Date()) {
        guard let index = websites.firstIndex(where: { $0.id == id }) else { return }
        let domain = websites[index].domain
        websites[index].isEnabled = isEnabled
        if !isEnabled {
            endBreaks(for: domain, at: date)
        }
        persistWebsites()
    }

    func deleteWebsite(id: UUID, at date: Date = Date()) {
        guard let domain = websites.first(where: { $0.id == id })?.domain else { return }
        websites.removeAll { $0.id == id }
        endBreaks(for: domain, at: date)
        persistWebsites()
    }

    func addSchedule() {
        schedules.append(
            FocusSchedule(
                name: "New schedule",
                startMinute: 9 * 60,
                endMinute: 12 * 60,
                weekdays: [2, 3, 4, 5, 6],
                isEnabled: true
            )
        )
        endAllBreaks()
        persistSchedules()
    }

    func updateSchedule(id: UUID, mutate: (inout FocusSchedule) -> Void) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }
        let previous = schedules[index]
        mutate(&schedules[index])
        schedules[index] = Self.sanitizedSchedule(schedules[index])
        let updated = schedules[index]
        if previous.startMinute != updated.startMinute
            || previous.endMinute != updated.endMinute
            || previous.weekdays != updated.weekdays
            || previous.isEnabled != updated.isEnabled {
            endAllBreaks()
        }
        persistSchedules()
    }

    func deleteSchedule(id: UUID) {
        schedules.removeAll { $0.id == id }
        endAllBreaks()
        persistSchedules()
    }

    func performMaintenance(at date: Date) {
        let sessionIsIncomplete = (manualSessionStartedAt == nil) != (manualSessionEndsAt == nil)
        let sessionHasInvalidOrder = manualSessionStartedAt.map { start in
            manualSessionEndsAt.map { $0 <= start } ?? false
        } ?? false
        if sessionIsIncomplete || sessionHasInvalidOrder {
            manualSessionStartedAt = nil
            manualSessionEndsAt = nil
            persistSession()
        }

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
    }

    private func persistWebsites() {
        if let data = try? encoder.encode(websites) {
            defaults.set(data, forKey: Key.websites)
        }
    }

    private func persistSchedules() {
        if let data = try? encoder.encode(schedules) {
            defaults.set(data, forKey: Key.schedules)
        }
    }

    private func persistSession() {
        defaults.set(manualSessionStartedAt, forKey: Key.manualSessionStartedAt)
        defaults.set(manualSessionEndsAt, forKey: Key.manualSessionEndsAt)
    }

    private func persistBreakRecords() {
        if let data = try? encoder.encode(breakRecords) {
            defaults.set(data, forKey: Key.breakRecords)
        }
    }

    private func endBreaks(for domain: String, at date: Date = Date()) {
        var changed = false
        for index in breakRecords.indices
        where breakRecords[index].domain == domain && breakRecords[index].isActive(at: date) {
            breakRecords[index].endedAt = date
            changed = true
        }
        if changed { persistBreakRecords() }
    }

    private static let defaultWebsites = [
        BlockedWebsite(domain: "instagram.com"),
        BlockedWebsite(domain: "reddit.com"),
        BlockedWebsite(domain: "x.com"),
        BlockedWebsite(domain: "tiktok.com"),
        BlockedWebsite(domain: "youtube.com")
    ]

    private static func validMinute(_ minute: Int) -> Int {
        min(max(minute, 0), (24 * 60) - 1)
    }

    private static func sanitizedWebsites(_ values: [BlockedWebsite]) -> [BlockedWebsite] {
        var seen: Set<String> = []
        return values.compactMap { value in
            guard let domain = DomainMatcher.normalizedDomain(from: value.domain),
                  seen.insert(domain).inserted
            else { return nil }

            return BlockedWebsite(id: value.id, domain: domain, isEnabled: value.isEnabled)
        }
    }

    private static func sanitizedSchedule(_ value: FocusSchedule) -> FocusSchedule {
        var result = value
        result.startMinute = validMinute(value.startMinute)
        result.endMinute = validMinute(value.endMinute)
        result.weekdays = Set(value.weekdays.filter { (1...7).contains($0) })
        if result.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.name = "Schedule"
        }
        return result
    }

    private static func sanitizedSchedules(_ values: [FocusSchedule]) -> [FocusSchedule] {
        var seenIDs: Set<UUID> = []
        return values.map { value in
            var result = sanitizedSchedule(value)
            if !seenIDs.insert(result.id).inserted {
                result.id = UUID()
                seenIDs.insert(result.id)
            }
            return result
        }
    }

    private static func sanitizedBreakRecords(_ values: [BreakRecord]) -> [BreakRecord] {
        var seenIDs: Set<UUID> = []
        return values.compactMap { value in
            guard let domain = DomainMatcher.normalizedDomain(from: value.domain),
                  let reason = TemporaryAccessPolicy.normalizedReason(value.reason),
                  value.scheduledEnd > value.requestedAt
            else { return nil }

            var result = value
            if !seenIDs.insert(result.id).inserted {
                result.id = UUID()
                seenIDs.insert(result.id)
            }
            result.domain = domain
            result.reason = reason
            if let endedAt = value.endedAt, endedAt < value.requestedAt {
                result.endedAt = value.requestedAt
            }
            return result
        }
        .sorted { $0.requestedAt > $1.requestedAt }
    }
}
