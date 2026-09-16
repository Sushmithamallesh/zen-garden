import Darwin
import Foundation

@main
struct CoreTests {
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

        expect(
            DomainMatcher.normalizedDomain(from: "https://www.Reddit.com/r/swift") == "reddit.com",
            "normalizes a full URL"
        )
        expect(
            DomainMatcher.normalizedDomain(from: "*.youtube.com") == "youtube.com",
            "normalizes wildcard input"
        )
        expect(
            DomainMatcher.normalizedDomain(from: "not a domain") == nil,
            "rejects malformed domains"
        )
        expect(
            DomainMatcher.normalizedDomain(from: "https://Reddit.com:443/r/swift") == "reddit.com",
            "normalizes ports and paths"
        )
        expect(
            DomainMatcher.normalizedDomain(from: "reddit..com") == nil
                && DomainMatcher.normalizedDomain(from: "-reddit.com") == nil
                && DomainMatcher.normalizedDomain(from: "reddit-.com") == nil,
            "rejects invalid DNS labels"
        )
        expect(
            DomainMatcher.normalizedDomain(from: String(repeating: "a", count: 64) + ".com") == nil,
            "rejects overlong DNS labels"
        )
        expect(
            DomainMatcher.matches(
                urlString: "https://old.reddit.com/r/macapps",
                blockedDomain: "reddit.com"
            ),
            "matches subdomains"
        )
        expect(
            !DomainMatcher.matches(
                urlString: "https://notreddit.com",
                blockedDomain: "reddit.com"
            ),
            "does not match lookalike domains"
        )
        expect(
            DomainMatcher.matches(
                urlString: "https://WWW.REDDIT.COM./r/macapps",
                blockedDomain: "reddit.com"
            ),
            "matches case-insensitive hosts with a trailing dot"
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        let workday = FocusSchedule(
            name: "Work",
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            weekdays: [2],
            isEnabled: true
        )
        let mondayMorning = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 17, hour: 10)
        )!
        let mondayEvening = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 17, hour: 18)
        )!
        expect(
            workday.activeInterval(containing: mondayMorning, calendar: calendar) != nil,
            "activates a daytime schedule"
        )
        expect(
            workday.activeInterval(containing: mondayEvening, calendar: calendar) == nil,
            "ends a daytime schedule"
        )

        let overnight = FocusSchedule(
            name: "Night",
            startMinute: 22 * 60,
            endMinute: 6 * 60,
            weekdays: [2],
            isEnabled: true
        )
        let tuesdayEarly = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 18, hour: 5)
        )!
        let tuesdayMorning = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 18, hour: 7)
        )!
        expect(
            overnight.activeInterval(containing: tuesdayEarly, calendar: calendar) != nil,
            "carries an overnight schedule into the next day"
        )
        expect(
            overnight.activeInterval(containing: tuesdayMorning, calendar: calendar) == nil,
            "ends an overnight schedule"
        )

        let allDayMonday = FocusSchedule(
            name: "All day",
            startMinute: 8 * 60,
            endMinute: 8 * 60,
            weekdays: [2],
            isEnabled: true
        )
        expect(
            allDayMonday.activeInterval(containing: mondayEvening, calendar: calendar) != nil,
            "supports an explicit all-day custom schedule"
        )

        let beforeSeven = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 18, hour: 6, minute: 59)
        )!
        let atSeven = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 18, hour: 7)
        )!
        let beforeFive = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 18, hour: 16, minute: 59)
        )!
        let atFive = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 18, hour: 17)
        )!
        expect(
            DailyFocusPolicy.activeInterval(
                containing: beforeSeven,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            ) == nil,
            "keeps the daily schedule off before its start"
        )
        expect(
            DailyFocusPolicy.activeInterval(
                containing: atSeven,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            ) != nil,
            "starts the daily schedule at 7 AM"
        )
        expect(
            DailyFocusPolicy.activeInterval(
                containing: beforeFive,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            ) != nil,
            "activates the daily boundary before its cutoff"
        )
        expect(
            DailyFocusPolicy.activeInterval(
                containing: atFive,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            ) == nil,
            "ends the daily boundary at its cutoff"
        )

        let saturdayNoon = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 22, hour: 12)
        )!
        let sundayNoon = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 23, hour: 12)
        )!
        expect(
            DailyFocusPolicy.activeInterval(
                containing: saturdayNoon,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            ) == nil,
            "keeps automatic blocking off on Saturday"
        )
        expect(
            DailyFocusPolicy.activeInterval(
                containing: sundayNoon,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            )?.duration == 24 * 60 * 60,
            "keeps automatic blocking active all Sunday"
        )
        expect(
            SundayLockPolicy.isLocked(domain: "x.com", at: sundayNoon, calendar: calendar)
                && SundayLockPolicy.isLocked(domain: "twitter.com", at: sundayNoon, calendar: calendar),
            "locks both Twitter domains on Sunday"
        )
        expect(
            !SundayLockPolicy.isLocked(domain: "reddit.com", at: sundayNoon, calendar: calendar)
                && !SundayLockPolicy.isLocked(domain: "x.com", at: saturdayNoon, calendar: calendar),
            "limits the permanent lock to Twitter on Sunday"
        )

        let saturdayOneAM = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 22, hour: 1)
        )!
        let mondayOneAM = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 24, hour: 1)
        )!
        expect(
            DailyFocusPolicy.activeInterval(
                containing: saturdayOneAM,
                startMinute: 22 * 60,
                cutoffMinute: 6 * 60,
                calendar: calendar
            ) == nil,
            "keeps Saturday free when a Friday overnight window would cross midnight"
        )
        expect(
            DailyFocusPolicy.activeInterval(
                containing: mondayOneAM,
                startMinute: 22 * 60,
                cutoffMinute: 6 * 60,
                calendar: calendar
            ) == nil,
            "does not extend Sunday policy into Monday for an overnight weekday window"
        )

        let springSunday = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)
        )!
        let fallSunday = calendar.date(
            from: DateComponents(year: 2026, month: 11, day: 1, hour: 12)
        )!
        expect(
            DailyFocusPolicy.activeInterval(
                containing: springSunday,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            )?.duration == 23 * 60 * 60,
            "keeps the complete 23-hour spring-forward Sunday blocked"
        )
        expect(
            DailyFocusPolicy.activeInterval(
                containing: fallSunday,
                startMinute: 7 * 60,
                cutoffMinute: 17 * 60,
                calendar: calendar
            )?.duration == 25 * 60 * 60,
            "keeps the complete 25-hour fall-back Sunday blocked"
        )

        let sundayDaytime = FocusSchedule(
            name: "Sunday morning",
            startMinute: 9 * 60,
            endMinute: 10 * 60,
            weekdays: [1],
            isEnabled: true
        )
        let springNineThirty = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 8, hour: 9, minute: 30)
        )!
        let springInterval = sundayDaytime.activeInterval(
            containing: springNineThirty,
            calendar: calendar
        )
        expect(
            springInterval != nil
                && calendar.component(.hour, from: springInterval!.start) == 9
                && springInterval!.duration == 60 * 60,
            "anchors schedules to wall-clock time across daylight saving changes"
        )

        let breakRecord = BreakRecord(
            domain: "reddit.com",
            reason: "Reply to a project question",
            requestedAt: mondayMorning,
            scheduledEnd: calendar.date(byAdding: .minute, value: 10, to: mondayMorning)!
        )
        expect(breakRecord.isActive(at: mondayMorning), "activates a requested break")
        expect(
            !breakRecord.isActive(at: calendar.date(byAdding: .minute, value: 10, to: mondayMorning)!),
            "expires a requested break on time"
        )
        expect(
            TemporaryAccessPolicy.normalizedReason("  Reply to one message  ") == "Reply to one message"
                && TemporaryAccessPolicy.normalizedReason("   \n ") == nil
                && TemporaryAccessPolicy.normalizedReason(
                    String(repeating: "a", count: TemporaryAccessPolicy.maximumReasonLength + 1)
                ) == nil,
            "normalizes reasons and rejects empty or oversized input"
        )

        let inlinePage = BlockPageDestination.inlinePage(
            html: "<html><body>Return to focus.</body></html>",
            domain: "instagram.com"
        )
        expect(
            inlinePage.hasPrefix("data:text/html;charset=utf-8;base64,")
                && inlinePage.hasSuffix("#instagram.com"),
            "builds a self-contained Chromium focus page"
        )
        expect(
            BlockPageDestination.fallbackPage(domain: "instagram.com")
                == "about:blank#zen-garden-instagram.com",
            "builds a browser-safe fallback destination"
        )

        if failures > 0 {
            print("\n\(failures) core test(s) failed.")
            exit(1)
        }

        print("\nAll core tests passed.")
    }
}
