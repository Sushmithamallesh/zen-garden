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

        if failures > 0 {
            print("\n\(failures) core test(s) failed.")
            exit(1)
        }

        print("\nAll core tests passed.")
    }
}
