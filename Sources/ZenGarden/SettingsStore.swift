import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var websites: [BlockedWebsite]
    @Published private(set) var schedules: [FocusSchedule]
    @Published private(set) var manualSessionStartedAt: Date?
    @Published private(set) var manualSessionEndsAt: Date?
    @Published private(set) var pausedUntil: Date?

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let websites = "zenGarden.websites.v1"
        static let schedules = "zenGarden.schedules.v1"
        static let manualSessionStartedAt = "zenGarden.manualSessionStartedAt.v1"
        static let manualSessionEndsAt = "zenGarden.manualSessionEndsAt.v1"
        static let pausedUntil = "zenGarden.pausedUntil.v1"
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

        manualSessionStartedAt = defaults.object(forKey: Key.manualSessionStartedAt) as? Date
        manualSessionEndsAt = defaults.object(forKey: Key.manualSessionEndsAt) as? Date
        pausedUntil = defaults.object(forKey: Key.pausedUntil) as? Date

        clearExpiredState(at: Date())
    }

    func focusState(at date: Date = Date(), calendar: Calendar = .current) -> FocusState {
        if let pause = pausedUntil, pause > date {
            return .inactive
        }

        if let manualEnd = manualSessionEndsAt, manualEnd > date {
            return FocusState(isActive: true, source: .manual, endsAt: manualEnd)
        }

        let activeSchedules = schedules.compactMap { schedule -> (FocusSchedule, DateInterval)? in
            guard let interval = schedule.activeInterval(containing: date, calendar: calendar) else { return nil }
            return (schedule, interval)
        }

        guard let active = activeSchedules.min(by: { $0.1.end < $1.1.end }) else {
            return .inactive
        }

        return FocusState(
            isActive: true,
            source: .schedule(active.0.name),
            endsAt: active.1.end
        )
    }

    func startSession(minutes: Int, now: Date = Date()) {
        let safeMinutes = min(max(minutes, 1), 12 * 60)
        manualSessionStartedAt = now
        manualSessionEndsAt = Calendar.current.date(byAdding: .minute, value: safeMinutes, to: now)
        pausedUntil = nil
        persistSession()
    }

    func endManualSession() {
        manualSessionStartedAt = nil
        manualSessionEndsAt = nil
        persistSession()
    }

    func pause(minutes: Int, now: Date = Date()) {
        pausedUntil = Calendar.current.date(byAdding: .minute, value: max(1, minutes), to: now)
        endManualSession()
        persistSession()
    }

    func resume() {
        pausedUntil = nil
        persistSession()
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

    private func clearExpiredState(at date: Date) {
        if let manualEnd = manualSessionEndsAt, manualEnd <= date {
            manualSessionStartedAt = nil
            manualSessionEndsAt = nil
        }
        if let pause = pausedUntil, pause <= date {
            pausedUntil = nil
        }
        persistSession()
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
        defaults.set(pausedUntil, forKey: Key.pausedUntil)
    }
}
