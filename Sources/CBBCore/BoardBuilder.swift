import Foundation

/// Everything fetched from ESPN in one refresh.
public struct BoardInputs: Codable, Sendable {
    /// Men's D1 scoreboards for Eastern days today-2 … today+7.
    public var menScoreboard: [Game]
    public var menSchedule: [Game]
    public var menRecord: String?
    public var womenSchedule: [Game]
    /// Women's scoreboard for today, so a live UConn women's score is fresh.
    public var womenToday: [Game]

    public init(menScoreboard: [Game], menSchedule: [Game], menRecord: String?,
                womenSchedule: [Game], womenToday: [Game]) {
        self.menScoreboard = menScoreboard
        self.menSchedule = menSchedule
        self.menRecord = menRecord
        self.womenSchedule = womenSchedule
        self.womenToday = womenToday
    }
}

public struct UConnSummary: Codable, Sendable {
    public let record: String?
    public let rank: Int?
    public let live: Game?
    public let next: Game?
    public let last: Game?
}

/// What the widget shows at one moment.
public struct Board: Codable, Sendable {
    public let now: Date
    public let uconn: UConnSummary
    public let women: Game?
    public let tickets: [TicketRow]
    public let comingUp: [Game]
    public let today: [Game]
    public let latest: [Game]

    public var allGames: [Game] {
        [uconn.live, uconn.next, uconn.last, women].compactMap { $0 } + comingUp + today + latest
    }
}

/// How many game rows each part of the extra-large widget holds.
public enum Slots {
    public static let rightColumn = 6
    public static let latestMinimum = 2
    public static let leftComingUp = 3
}

public enum BoardBuilder {
    static let comingUpDays = 7
    static let latestDays = 2
    static let womenAheadDays = 7
    static let womenBackDays = 3

    public static func build(_ inputs: BoardInputs, now: Date) -> Board {
        let cal = Calendar.eastern
        let today = cal.startOfDay(for: now)
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: today)! }

        let uconn = uconnSummary(inputs, now: now)
        let women = womenLine(inputs, now: now)
        let tickets = TicketSchedule.rows(at: now)
        let scoreboard = dedupe(inputs.menScoreboard).filter { $0.state != .postponed }

        // Right column: Latest keeps at least `latestMinimum` rows when it has results.
        let latestCandidates = scoreboard
            .filter { $0.state == .final && $0.start >= day(-latestDays) && $0.start < today }
            .filter(BigGames.qualifiesForScores)
            .sorted(by: latestOrder)
        let todayCandidates = scoreboard
            .filter { $0.state == .live || ($0.start >= today && $0.start < day(1)) }
            .filter(BigGames.qualifiesForScores)
        let todayCap = Slots.rightColumn - min(Slots.latestMinimum, latestCandidates.count)
        let todayGames = Array(todayCandidates.sorted(by: BigGames.importanceOrder).prefix(todayCap))
            .sorted(by: displayOrder)
        let latest = Array(latestCandidates.prefix(Slots.rightColumn - todayGames.count))

        // Left column: Coming up shrinks by one row for each extra ticket row.
        let comingUpCap = max(0, Slots.leftComingUp - max(0, tickets.count - 1))
        let comingUp = scoreboard
            .filter { $0.state == .pre && $0.start >= day(1) && $0.start < day(comingUpDays + 1) }
            .filter { $0.id != uconn.next?.id }
            .filter(BigGames.qualifiesForComingUp)
            .sorted(by: BigGames.comingUpOrder)

        return Board(
            now: now, uconn: uconn, women: women, tickets: tickets,
            comingUp: Array(comingUp.prefix(comingUpCap)), today: todayGames, latest: latest
        )
    }

    // MARK: - UConn

    private static func uconnSummary(_ inputs: BoardInputs, now: Date) -> UConnSummary {
        let id = BigGames.uconnID
        let live = inputs.menScoreboard.first { $0.involves(id) && $0.state == .live }
            ?? inputs.menSchedule.first { $0.involves(id) && $0.state == .live }
        let next = inputs.menSchedule.filter { $0.involves(id) && $0.state == .pre }.min { $0.start < $1.start }
        let last = inputs.menSchedule.filter { $0.involves(id) && $0.state == .final }.max { $0.start < $1.start }
        let rank = [live, next, last].compactMap { $0?.competitor(id) }.first?.rank
        return UConnSummary(record: inputs.menRecord, rank: rank, live: live, next: next, last: last)
    }

    private static func womenLine(_ inputs: BoardInputs, now: Date) -> Game? {
        let id = BigGames.uconnID
        func vsRanked(_ g: Game) -> Bool { g.involves(id) && g.opponent(of: id)?.rank != nil }
        let games = inputs.womenSchedule.filter(vsRanked)

        if let live = (inputs.womenToday + games).first(where: { $0.state == .live && vsRanked($0) }) {
            return live
        }
        let ahead = now.addingTimeInterval(Double(womenAheadDays) * 86400)
        if let next = games.filter({ $0.state == .pre && $0.start >= now && $0.start <= ahead }).min(by: { $0.start < $1.start }) {
            return next
        }
        let back = now.addingTimeInterval(-Double(womenBackDays) * 86400)
        return games.filter { $0.state == .final && $0.start >= back }.max { $0.start < $1.start }
    }

    // MARK: - Ordering

    /// Live, then upcoming by tip, then finals by tip.
    private static func displayOrder(_ a: Game, _ b: Game) -> Bool {
        func rank(_ s: GameState) -> Int { s == .live ? 0 : s == .pre ? 1 : 2 }
        if rank(a.state) != rank(b.state) { return rank(a.state) < rank(b.state) }
        return a.start < b.start
    }

    /// Upsets, then ranked vs ranked, then prominent, then the rest, blowouts last; newest first within a group.
    private static func latestOrder(_ a: Game, _ b: Game) -> Bool {
        func group(_ g: Game) -> Int {
            if BigGames.isUpset(g) { return 0 }
            if BigGames.isBothRanked(g) { return 1 }
            if BigGames.isProminent(g) { return 2 }
            if BigGames.isBlowout(g) { return 4 }
            return 3
        }
        if group(a) != group(b) { return group(a) < group(b) }
        return a.start > b.start
    }

    private static func dedupe(_ games: [Game]) -> [Game] {
        var seen = Set<String>()
        return games.filter { seen.insert($0.id).inserted }
    }
}
