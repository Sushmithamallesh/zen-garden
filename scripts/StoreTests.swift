import Darwin
import Foundation

@main
struct StoreTests {
    @MainActor
    static func main() {
        var failures = 0

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if condition() {
                print("✓ \(message)")
            } else {
                failures += 1
                print("✗ \(message)")
            }
        }

        let suiteName = "com.sushmithamallesh.zengarden.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("✗ could not create isolated preferences")
            exit(1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        let sixFiftyNineAM = calendar.date(byAdding: .minute, value: (6 * 60) + 59, to: dayStart)!
        let sevenAM = calendar.date(byAdding: .hour, value: 7, to: dayStart)!
        let fourPM = calendar.date(byAdding: .hour, value: 16, to: dayStart)!
        let fourFiftyFive = calendar.date(byAdding: .minute, value: (16 * 60) + 55, to: dayStart)!
        let fourFiftyNine = calendar.date(byAdding: .minute, value: (16 * 60) + 59, to: dayStart)!
        let fivePM = calendar.date(byAdding: .hour, value: 17, to: dayStart)!
        let sixPM = calendar.date(byAdding: .hour, value: 18, to: dayStart)!

        let dailyStore = SettingsStore(defaults: defaults)
        expect(
            dailyStore.focusState(at: sixFiftyNineAM, calendar: calendar) == .inactive,
            "keeps daily blocking off before 7 AM"
        )
        expect(
            dailyStore.focusState(at: sevenAM, calendar: calendar).source == .daily,
            "starts daily blocking at 7 AM"
        )
        expect(
            dailyStore.focusState(at: fourPM, calendar: calendar).source == .daily,
            "uses the daily boundary before the cutoff"
        )
        expect(
            dailyStore.focusState(at: fivePM, calendar: calendar) == .inactive,
            "ends the daily boundary exactly at the cutoff"
        )
        expect(
            !dailyStore.requestBreak(
                domain: "instagram.com",
                reason: "Should be rejected",
                minutes: 10,
                now: sixPM
            ),
            "rejects a break when focus is inactive"
        )
        expect(
            dailyStore.requestBreak(
                domain: "instagram.com",
                reason: "Reply to one message",
                minutes: 15,
                now: fourFiftyFive
            ),
            "creates a reason-gated break during focus"
        )
        expect(
            dailyStore.breakRecords.first?.scheduledEnd == fivePM,
            "caps a break at the end of its focus session"
        )
        expect(
            dailyStore.isDomainTemporarilyAllowed("instagram.com", at: fourFiftyNine),
            "allows only the requested domain during a break"
        )
        expect(
            !dailyStore.requestBreak(
                domain: "instagram.com",
                reason: "Duplicate request",
                minutes: 5,
                now: fourFiftyNine
            ),
            "prevents overlapping exceptions for the same domain"
        )
        expect(
            !dailyStore.isDomainTemporarilyAllowed("instagram.com", at: fivePM),
            "revokes the exception when focus ends"
        )
        let nextMorning = calendar.date(byAdding: .hour, value: 8, to: calendar.date(byAdding: .day, value: 1, to: dayStart)!)!
        expect(
            dailyStore.pendingDigestDate(at: nextMorning, calendar: calendar) == dayStart,
            "keeps a missed digest pending after an overnight sleep"
        )
        dailyStore.markDigestSent(for: dayStart, calendar: calendar)
        expect(
            dailyStore.pendingDigestDate(at: nextMorning, calendar: calendar) == nil,
            "does not resend a completed daily digest"
        )

        let persistedStore = SettingsStore(defaults: defaults)
        expect(
            persistedStore.breakRecords.count == 1,
            "persists the break reason locally"
        )

        let overlapSuite = "com.sushmithamallesh.zengarden.tests.\(UUID().uuidString)"
        let overlapDefaults = UserDefaults(suiteName: overlapSuite)!
        overlapDefaults.removePersistentDomain(forName: overlapSuite)
        defer { overlapDefaults.removePersistentDomain(forName: overlapSuite) }

        let overlapStore = SettingsStore(defaults: overlapDefaults)
        overlapStore.startSession(minutes: 120, now: fourPM)
        let overlapState = overlapStore.focusState(at: fourPM, calendar: calendar)
        expect(
            overlapState.source == .manual && overlapState.endsAt == sixPM,
            "keeps the longest overlapping focus boundary active"
        )

        let weeklySuite = "com.sushmithamallesh.zengarden.tests.\(UUID().uuidString)"
        let weeklyDefaults = UserDefaults(suiteName: weeklySuite)!
        weeklyDefaults.removePersistentDomain(forName: weeklySuite)
        defer { weeklyDefaults.removePersistentDomain(forName: weeklySuite) }

        var policyCalendar = Calendar(identifier: .gregorian)
        policyCalendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let saturdayNoon = policyCalendar.date(
            from: DateComponents(year: 2026, month: 8, day: 22, hour: 12)
        )!
        let sundayNoon = policyCalendar.date(
            from: DateComponents(year: 2026, month: 8, day: 23, hour: 12)
        )!
        let weeklyStore = SettingsStore(defaults: weeklyDefaults)

        expect(
            weeklyStore.focusState(at: saturdayNoon, calendar: policyCalendar) == .inactive,
            "keeps the automatic schedule off Saturday"
        )
        expect(
            weeklyStore.focusState(at: sundayNoon, calendar: policyCalendar).source == .daily,
            "keeps the automatic schedule active all Sunday"
        )
        let sundayWebsites = weeklyStore.websitesForBlocking(
            at: sundayNoon,
            calendar: policyCalendar
        )
        expect(
            sundayWebsites.contains { $0.domain == "x.com" && $0.isEnabled }
                && sundayWebsites.contains { $0.domain == "twitter.com" && $0.isEnabled },
            "enforces both Twitter domains on Sunday"
        )
        expect(
            !weeklyStore.requestBreak(
                domain: "x.com",
                reason: "Try to bypass Sunday",
                minutes: 10,
                now: sundayNoon
            ),
            "rejects Twitter access requests on Sunday"
        )
        expect(
            !weeklyStore.availableBreakDomains(at: sundayNoon, calendar: policyCalendar).contains("x.com"),
            "removes Twitter from Sunday break choices"
        )
        weeklyStore.setDailyFocusEnabled(false)
        expect(
            weeklyStore.focusState(at: sundayNoon, calendar: policyCalendar).source == .daily,
            "keeps the Sunday lock active when weekday blocking is disabled"
        )

        if failures > 0 {
            print("\n\(failures) store test(s) failed.")
            exit(1)
        }

        print("\nAll store tests passed.")
    }
}
