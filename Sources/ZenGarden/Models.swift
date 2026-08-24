import Foundation

struct BlockedWebsite: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var domain: String
    var isEnabled: Bool = true
}

struct FocusSchedule: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String
    var startMinute: Int
    var endMinute: Int
    var weekdays: Set<Int>
    var isEnabled: Bool = true

    static let workday = FocusSchedule(
        name: "Quiet work",
        startMinute: 9 * 60,
        endMinute: 17 * 60,
        weekdays: [2, 3, 4, 5, 6],
        isEnabled: false
    )

    func activeInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        guard isEnabled else { return nil }

        let dayStart = calendar.startOfDay(for: date)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: date)
        let minuteOfDay = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let todayWeekday = calendar.component(.weekday, from: date)

        if startMinute < endMinute {
            guard weekdays.contains(todayWeekday),
                  minuteOfDay >= startMinute,
                  minuteOfDay < endMinute,
                  let start = calendar.date(byAdding: .minute, value: startMinute, to: dayStart),
                  let end = calendar.date(byAdding: .minute, value: endMinute, to: dayStart)
            else { return nil }

            return DateInterval(start: start, end: end)
        }

        if startMinute > endMinute {
            if minuteOfDay >= startMinute,
               weekdays.contains(todayWeekday),
               let start = calendar.date(byAdding: .minute, value: startMinute, to: dayStart),
               let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart),
               let end = calendar.date(byAdding: .minute, value: endMinute, to: nextDay) {
                return DateInterval(start: start, end: end)
            }

            if minuteOfDay < endMinute,
               let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart),
               weekdays.contains(calendar.component(.weekday, from: previousDay)),
               let start = calendar.date(byAdding: .minute, value: startMinute, to: previousDay),
               let end = calendar.date(byAdding: .minute, value: endMinute, to: dayStart) {
                return DateInterval(start: start, end: end)
            }

            return nil
        }

        guard weekdays.contains(todayWeekday),
              let end = calendar.date(byAdding: .day, value: 1, to: dayStart)
        else { return nil }

        return DateInterval(start: dayStart, end: end)
    }
}

enum FocusSource: Equatable, Sendable {
    case manual
    case daily
    case schedule(String)
}

struct FocusState: Equatable, Sendable {
    var isActive: Bool
    var source: FocusSource?
    var endsAt: Date?

    static let inactive = FocusState(isActive: false, source: nil, endsAt: nil)
}

struct BreakRecord: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var domain: String
    var reason: String
    var requestedAt: Date
    var scheduledEnd: Date
    var endedAt: Date?

    func isActive(at date: Date) -> Bool {
        requestedAt <= date && (endedAt ?? scheduledEnd) > date
    }

    func activeDuration(until date: Date = Date()) -> TimeInterval {
        max(0, min(endedAt ?? date, scheduledEnd).timeIntervalSince(requestedAt))
    }
}

enum DailyFocusPolicy {
    static let defaultCutoffMinute = 17 * 60

    static func activeInterval(
        containing date: Date,
        cutoffMinute: Int,
        calendar: Calendar = .current
    ) -> DateInterval? {
        let safeCutoff = min(max(cutoffMinute, 1), (24 * 60) - 1)
        let dayStart = calendar.startOfDay(for: date)
        guard let cutoff = calendar.date(byAdding: .minute, value: safeCutoff, to: dayStart),
              date < cutoff
        else { return nil }

        return DateInterval(start: dayStart, end: cutoff)
    }
}

enum DomainMatcher {
    static func normalizedDomain(from input: String) -> String? {
        var candidate = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !candidate.isEmpty else { return nil }

        if candidate.hasPrefix("*.") {
            candidate.removeFirst(2)
        }

        if !candidate.contains("://") {
            candidate = "https://" + candidate
        }

        guard let components = URLComponents(string: candidate),
              var host = components.host?.lowercased(),
              !host.isEmpty
        else { return nil }

        while host.hasSuffix(".") {
            host.removeLast()
        }

        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }

        guard !host.isEmpty,
              !host.contains(" "),
              host.range(of: "^[a-z0-9.-]+$", options: .regularExpression) != nil
        else { return nil }

        return host
    }

    static func host(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              var host = url.host?.lowercased()
        else { return nil }

        while host.hasSuffix(".") {
            host.removeLast()
        }
        return host
    }

    static func matches(urlString: String, blockedDomain: String) -> Bool {
        guard let host = host(from: urlString),
              let domain = normalizedDomain(from: blockedDomain)
        else { return false }

        return host == domain || host.hasSuffix("." + domain)
    }

    static func firstMatch(urlString: String, in websites: [BlockedWebsite]) -> BlockedWebsite? {
        websites.first { website in
            website.isEnabled && matches(urlString: urlString, blockedDomain: website.domain)
        }
    }
}
