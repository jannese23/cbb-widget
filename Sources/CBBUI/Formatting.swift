import CBBCore
import Foundation

/// Display strings. Times show in the Mac's own time zone.
enum Fmt {
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = format
        return f
    }

    private static let time = formatter("h:mm a")
    private static let dayTime = formatter("EEE h:mm a")
    private static let weekday = formatter("EEE")
    private static let dayDate = formatter("EEE, MMM d")
    private static let monthDay = formatter("MMM d")

    static func time(_ d: Date) -> String { time.string(from: d) }
    static func dayDate(_ d: Date) -> String { dayDate.string(from: d) }

    /// "Tonight 6:30 PM", "Sun 5:30 PM", or "Nov 25, 7:00 PM" beyond a week.
    static func when(_ d: Date, now: Date) -> String {
        let cal = Calendar.current
        if cal.isDate(d, inSameDayAs: now) {
            return (cal.component(.hour, from: d) >= 17 ? "Tonight " : "Today ") + time.string(from: d)
        }
        if d.timeIntervalSince(now) < 6 * 86400 { return dayTime.string(from: d) }
        return monthDay.string(from: d) + ", " + time.string(from: d)
    }

    /// Kickoff time for a row: just the time today, else weekday + time.
    static func tip(_ d: Date, now: Date) -> String {
        Calendar.current.isDate(d, inSameDayAs: now) ? time.string(from: d) : dayTime.string(from: d)
    }

    /// "Final" today, "Final · Tue" on earlier days.
    static func final(_ d: Date, now: Date) -> String {
        Calendar.current.isDate(d, inSameDayAs: now) ? "Final" : "Final · " + weekday.string(from: d)
    }

    /// "Sun 10 PM" for claim opens; "Thu 11:59 PM" for closes.
    static func claim(_ d: Date) -> String {
        let f = Calendar.current.component(.minute, from: d) == 0 ? formatter("EEE h a") : dayTime
        return f.string(from: d)
    }

    static func record(_ r: String) -> String { r.replacingOccurrences(of: "-", with: "–") }

    /// "W 83–41" / "L 66–77" from UConn's side.
    static func result(_ g: Game, for teamID: String) -> String? {
        guard let us = g.competitor(teamID)?.score, let them = g.opponent(of: teamID)?.score else { return nil }
        let letter = g.state == .final ? (us > them ? "W " : "L ") : ""
        return "\(letter)\(us)–\(them)"
    }

    static func arena(_ a: Arena) -> String { a.rawValue }
}
