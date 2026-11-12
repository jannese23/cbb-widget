import Foundation

public enum League: String, Codable, Sendable {
    case men = "mens-college-basketball"
    case women = "womens-college-basketball"
}

public enum GameState: String, Codable, Sendable {
    case pre, live, final
    /// Postponed, canceled or suspended: never shown as a result.
    case postponed
}

public struct Team: Codable, Hashable, Sendable {
    public let id: String
    public let abbreviation: String
    public let location: String

    public init(id: String, abbreviation: String, location: String) {
        self.id = id
        self.abbreviation = abbreviation
        self.location = location
    }
}

public struct Competitor: Codable, Hashable, Sendable {
    public let team: Team
    /// AP rank; nil when unranked (ESPN sends 99).
    public let rank: Int?
    public let score: Int?
    public let isHome: Bool

    public init(team: Team, rank: Int?, score: Int?, isHome: Bool) {
        self.team = team
        self.rank = rank
        self.score = score
        self.isHome = isHome
    }
}

public struct Game: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let league: League
    public let start: Date
    public let state: GameState
    public let period: Int
    /// ESPN `status.type.shortDetail`, e.g. "Final", "2nd 4:20", "11/13 - 7:30 PM EST".
    public let statusText: String
    public let venue: String?
    public let home: Competitor
    public let away: Competitor
    public let link: URL?

    public init(id: String, league: League, start: Date, state: GameState, period: Int, statusText: String,
                venue: String?, home: Competitor, away: Competitor, link: URL?) {
        self.id = id
        self.league = league
        self.start = start
        self.state = state
        self.period = period
        self.statusText = statusText
        self.venue = venue
        self.home = home
        self.away = away
        self.link = link
    }

    public var competitors: [Competitor] { [home, away] }

    public func involves(_ teamID: String) -> Bool {
        home.team.id == teamID || away.team.id == teamID
    }

    public func opponent(of teamID: String) -> Competitor? {
        if home.team.id == teamID { return away }
        if away.team.id == teamID { return home }
        return nil
    }

    public func competitor(_ teamID: String) -> Competitor? {
        competitors.first { $0.team.id == teamID }
    }

    /// The team ahead on the scoreboard (final or live); nil when level or unscored.
    public var leader: Competitor? {
        guard let h = home.score, let a = away.score, h != a else { return nil }
        return h > a ? home : away
    }

    public var trailer: Competitor? {
        guard let leader else { return nil }
        return leader == home ? away : home
    }

    public var winner: Competitor? { state == .final ? leader : nil }
    public var loser: Competitor? { state == .final ? trailer : nil }
}
