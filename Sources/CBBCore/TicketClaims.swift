import Foundation

public enum Squad: String, Codable, Sendable {
    case men = "Men's"
    case women = "Women's"
}

public enum Arena: String, Codable, Sendable {
    case gampel = "Gampel"
    case peoplesBank = "PeoplesBank"
}

public struct TicketClaim: Codable, Hashable, Sendable {
    public let squad: Squad
    public let opponent: String
    public let arena: Arena
    /// Noon Eastern on the game date (the page lists dates, not tip times).
    public let gameDay: Date
    public let opens: Date
    public let closes: Date
}

public enum TicketState: String, Codable, Sendable {
    case quiet, soon, open
}

public struct TicketRow: Codable, Hashable, Sendable {
    public let claim: TicketClaim
    public let state: TicketState
}

/// UConn's 2026–27 student ticket claim schedule, from
/// https://uconnhuskies.com/sports/2018/6/12/student-basketball-tickets (read 2026-11-12).
/// A claim opens at 10:00 PM on its open date and closes at 11:59 PM on its close date, Eastern.
/// Men's home games at both arenas; women's only at Gampel.
public enum TicketSchedule {
    public static let claimURL = URL(string: "https://uconntickets.com")!

    static let soonWindow: TimeInterval = 48 * 3600

    // (squad, game date, opponent, arena, opens, closes)
    private static let table: [(Squad, String, String, String, String, String)] = [
        (.men, "2026-10-27", "Purdue", "PBA", "2026-10-15", "2026-10-18"),
        (.men, "2026-11-02", "Gardner-Webb", "PBA", "2026-10-18", "2026-10-21"),
        (.men, "2026-11-09", "Wagner", "GP", "2026-10-24", "2026-10-27"),
        (.men, "2026-11-13", "Ohio State", "PBA", "2026-10-28", "2026-10-31"),
        (.men, "2026-11-30", "Rider", "GP", "2026-11-15", "2026-11-18"),
        (.men, "2026-12-08", "Mississippi Valley St", "GP", "2026-11-22", "2026-11-25"),
        (.men, "2026-12-12", "Kansas", "GP", "2026-11-28", "2026-12-01"),
        (.men, "2026-12-15", "Delaware State", "PBA", "2026-11-29", "2026-12-02"),
        (.men, "2026-12-23", "Georgetown", "PBA", "2026-12-07", "2026-12-10"),
        (.men, "2027-01-06", "DePaul", "GP", "2026-12-21", "2026-12-24"),
        (.men, "2027-01-12", "Marquette", "GP", "2026-12-27", "2026-12-30"),
        (.men, "2027-01-16", "Xavier", "GP", "2026-12-30", "2027-01-02"),
        (.men, "2027-01-23", "Butler", "PBA", "2027-01-08", "2027-01-11"),
        (.men, "2027-02-03", "Villanova", "PBA", "2027-01-17", "2027-01-20"),
        (.men, "2027-02-07", "Creighton", "PBA", "2027-01-22", "2027-01-25"),
        (.men, "2027-02-17", "Seton Hall", "GP", "2027-02-01", "2027-02-04"),
        (.men, "2027-02-27", "Providence", "GP", "2027-02-11", "2027-02-14"),
        (.men, "2027-03-02", "St. John's", "PBA", "2027-02-14", "2027-02-17"),
        (.women, "2026-10-25", "Army", "GP", "2026-10-14", "2026-10-17"),
        (.women, "2026-11-08", "Iowa", "GP", "2026-10-22", "2026-10-25"),
        (.women, "2026-12-02", "UNLV", "GP", "2026-11-16", "2026-11-19"),
        (.women, "2026-12-16", "Creighton", "GP", "2026-12-01", "2026-12-04"),
        (.women, "2027-01-28", "DePaul", "GP", "2027-01-14", "2027-01-17"),
        (.women, "2027-02-10", "Villanova", "GP", "2027-01-25", "2027-01-28"),
        (.women, "2027-02-13", "Xavier", "GP", "2027-01-27", "2027-01-30"),
        (.women, "2027-02-28", "Butler", "GP", "2027-02-12", "2027-02-15"),
    ]

    public static let all: [TicketClaim] = table.map { squad, game, opponent, arena, opens, closes in
        TicketClaim(
            squad: squad, opponent: opponent, arena: arena == "GP" ? .gampel : .peoplesBank,
            gameDay: eastern(game, hour: 12, minute: 0),
            opens: eastern(opens, hour: 22, minute: 0),
            closes: eastern(closes, hour: 23, minute: 59)
        )
    }

    public static func state(of claim: TicketClaim, at now: Date) -> TicketState? {
        if now >= claim.closes { return nil }
        if now >= claim.opens { return .open }
        if now >= claim.opens.addingTimeInterval(-soonWindow) { return .soon }
        return .quiet
    }

    /// Every open or soon claim (by open time); otherwise the single next claim; otherwise nothing.
    public static func rows(at now: Date) -> [TicketRow] {
        let upcoming = all
            .compactMap { claim in state(of: claim, at: now).map { TicketRow(claim: claim, state: $0) } }
            .sorted { $0.claim.opens < $1.claim.opens }
        let active = upcoming.filter { $0.state != .quiet }
        if !active.isEmpty { return active }
        return Array(upcoming.prefix(1))
    }

    /// Instants after `now` (and within `within` seconds) when some claim changes state.
    public static func boundaries(after now: Date, within: TimeInterval) -> [Date] {
        let end = now.addingTimeInterval(within)
        return Set(all.flatMap { [$0.opens.addingTimeInterval(-soonWindow), $0.opens, $0.closes] })
            .filter { $0 > now && $0 <= end }
            .sorted()
    }

    private static func eastern(_ day: String, hour: Int, minute: Int) -> Date {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        var c = DateComponents()
        (c.year, c.month, c.day, c.hour, c.minute) = (parts[0], parts[1], parts[2], hour, minute)
        return Calendar.eastern.date(from: c)!
    }
}

extension Calendar {
    /// Gregorian calendar in America/New_York: ESPN's day boundaries and the claim schedule's clock.
    public static let eastern: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }()
}
