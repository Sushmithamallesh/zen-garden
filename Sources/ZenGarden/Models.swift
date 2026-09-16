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
        name: "Work hours",
        startMinute: 9 * 60,
        endMinute: 17 * 60,
        weekdays: [2, 3, 4, 5, 6],
        isEnabled: false
    )

    func activeInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        guard isEnabled else { return nil }

        let dayStart = calendar.startOfDay(for: date)
        let todayWeekday = calendar.component(.weekday, from: date)

        if startMinute < endMinute {
            guard weekdays.contains(todayWeekday),
                  let start = WallClock.date(atMinute: startMinute, on: dayStart, calendar: calendar),
                  let end = WallClock.date(atMinute: endMinute, on: dayStart, calendar: calendar)
            else { return nil }

            let interval = DateInterval(start: start, end: end)
            return interval.containsHalfOpen(date) ? interval : nil
        }

        if startMinute > endMinute {
            if weekdays.contains(todayWeekday),
               let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart),
               let start = WallClock.date(atMinute: startMinute, on: dayStart, calendar: calendar),
               let end = WallClock.date(atMinute: endMinute, on: nextDay, calendar: calendar) {
                let interval = DateInterval(start: start, end: end)
                if interval.containsHalfOpen(date) { return interval }
            }

            if let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart),
               weekdays.contains(calendar.component(.weekday, from: previousDay)),
               let start = WallClock.date(atMinute: startMinute, on: previousDay, calendar: calendar),
               let end = WallClock.date(atMinute: endMinute, on: dayStart, calendar: calendar) {
                let interval = DateInterval(start: start, end: end)
                if interval.containsHalfOpen(date) { return interval }
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

enum TemporaryAccessPolicy {
    static let maximumReasonLength = 500

    static func normalizedReason(_ input: String) -> String? {
        let reason = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty, reason.count <= maximumReasonLength else { return nil }
        return reason
    }
}

enum DailyFocusPolicy {
    static let defaultStartMinute = 7 * 60
    static let defaultCutoffMinute = 17 * 60

    static func activeInterval(
        containing date: Date,
        startMinute: Int,
        cutoffMinute: Int,
        calendar: Calendar = .current
    ) -> DateInterval? {
        let weekday = calendar.component(.weekday, from: date)
        let dayStart = calendar.startOfDay(for: date)

        if weekday == 7 {
            return nil
        }

        if weekday == 1 {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return nil
            }
            return DateInterval(start: dayStart, end: nextDay)
        }

        let safeStart = min(max(startMinute, 0), (24 * 60) - 1)
        let safeCutoff = min(max(cutoffMinute, 0), (24 * 60) - 1)
        guard safeStart != safeCutoff else { return nil }

        if safeStart < safeCutoff {
            guard let start = WallClock.date(atMinute: safeStart, on: dayStart, calendar: calendar),
                  let cutoff = WallClock.date(atMinute: safeCutoff, on: dayStart, calendar: calendar)
            else { return nil }

            let interval = DateInterval(start: start, end: cutoff)
            return interval.containsHalfOpen(date) ? interval : nil
        }

        if let start = WallClock.date(atMinute: safeStart, on: dayStart, calendar: calendar),
           let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart),
           let cutoff = WallClock.date(atMinute: safeCutoff, on: nextDay, calendar: calendar) {
            let interval = DateInterval(start: start, end: cutoff)
            if interval.containsHalfOpen(date) { return interval }
        }

        if let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart),
           (2...6).contains(calendar.component(.weekday, from: previousDay)),
           let start = WallClock.date(atMinute: safeStart, on: previousDay, calendar: calendar),
           let cutoff = WallClock.date(atMinute: safeCutoff, on: dayStart, calendar: calendar) {
            let interval = DateInterval(start: start, end: cutoff)
            if interval.containsHalfOpen(date) { return interval }
        }

        return nil
    }
}

enum SundayLockPolicy {
    static let domains = ["x.com", "twitter.com"]

    static func isActive(at date: Date, calendar: Calendar = .current) -> Bool {
        calendar.component(.weekday, from: date) == 1
    }

    static func isLocked(
        domain input: String,
        at date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard isActive(at: date, calendar: calendar),
              let domain = DomainMatcher.normalizedDomain(from: input)
        else { return false }

        return domains.contains(domain)
    }
}

enum BlockPageDestination {
    static func inlinePage(html: String, domain: String) -> String {
        let encodedPage = Data(html.utf8).base64EncodedString()
        let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
            ?? domain
        return "data:text/html;charset=utf-8;base64,\(encodedPage)#\(encodedDomain)"
    }

    static func fallbackPage(domain: String) -> String {
        "about:blank#zen-garden-\(domain)"
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

        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard !host.isEmpty,
              host.count <= 253,
              !host.contains(" "),
              !labels.isEmpty,
              labels.allSatisfy({ label in
                  guard !label.isEmpty,
                        label.count <= 63,
                        label.first?.isASCII == true,
                        label.last?.isASCII == true,
                        label.first?.isLetter == true || label.first?.isNumber == true,
                        label.last?.isLetter == true || label.last?.isNumber == true
                  else { return false }

                  return label.allSatisfy { character in
                      character.isASCII && (character.isLetter || character.isNumber || character == "-")
                  }
              })
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

enum WallClock {
    static func date(atMinute minute: Int, on day: Date, calendar: Calendar) -> Date? {
        let safeMinute = min(max(minute, 0), (24 * 60) - 1)
        let dayStart = calendar.startOfDay(for: day)
        let searchStart = dayStart.addingTimeInterval(-1)
        let components = DateComponents(
            hour: safeMinute / 60,
            minute: safeMinute % 60,
            second: 0
        )

        guard let result = calendar.nextDate(
            after: searchStart,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ),
        calendar.isDate(result, inSameDayAs: dayStart)
        else { return nil }

        return result
    }
}

private extension DateInterval {
    func containsHalfOpen(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
