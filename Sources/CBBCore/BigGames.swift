import Foundation

public enum Caption: String, Codable, Sendable {
    case bothRanked = "Both ranked"
    case upset = "Upset"
}

/// How much a game matters, most important first.
public enum Tier: Int, Comparable, Sendable {
    case uconn = 0, bothRanked, prominent, upsetInProgress, rankedVsUnranked, other

    public static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }
}

/// Which games are worth showing, and in what order (spec: "What counts as a big game").
public enum BigGames {
    public static let uconnID = "41"

    /// Big-name programs: a game between any two of them counts, whatever their ranks.
    /// Duke, North Carolina, Kentucky, Kansas, UCLA, Indiana, Michigan State, Villanova,
    /// Louisville, Syracuse, Arizona, Gonzaga.
    public static let prominentProgramIDs: Set<String> = [
        "150", "153", "96", "2305", "26", "84", "127", "222", "97", "183", "12", "2250",
    ]

    /// A ranked team beating one ranked this many places higher is an upset.
    static let upsetRankGap = 8
    /// A ranked team beating an unranked one by at least this much is a blowout.
    static let blowoutMargin = 20

    public static func isUConn(_ g: Game) -> Bool { g.involves(uconnID) }

    public static func isBothRanked(_ g: Game) -> Bool { g.home.rank != nil && g.away.rank != nil }

    public static func isProminent(_ g: Game) -> Bool {
        prominentProgramIDs.contains(g.home.team.id) && prominentProgramIDs.contains(g.away.team.id)
    }

    public static func isUpset(_ g: Game) -> Bool {
        guard let w = g.winner, let l = g.loser else { return false }
        return wouldBeUpset(winner: w, loser: l)
    }

    public static func isUpsetInProgress(_ g: Game) -> Bool {
        guard g.state == .live, g.period >= 2, let lead = g.leader, let trail = g.trailer else { return false }
        return wouldBeUpset(winner: lead, loser: trail)
    }

    public static func isBlowout(_ g: Game) -> Bool {
        guard let w = g.winner, let l = g.loser, w.rank != nil, l.rank == nil,
              let ws = w.score, let ls = l.score else { return false }
        return ws - ls >= blowoutMargin
    }

    public static func qualifiesForComingUp(_ g: Game) -> Bool {
        isUConn(g) || isBothRanked(g) || isProminent(g) || isTopTenVsUnranked(g)
    }

    public static func qualifiesForScores(_ g: Game) -> Bool {
        isUConn(g) || g.home.rank != nil || g.away.rank != nil || isProminent(g)
    }

    public static func tier(_ g: Game) -> Tier {
        if isUConn(g) { return .uconn }
        if isBothRanked(g) { return .bothRanked }
        if isProminent(g) { return .prominent }
        if isUpsetInProgress(g) { return .upsetInProgress }
        if g.home.rank != nil || g.away.rank != nil { return .rankedVsUnranked }
        return .other
    }

    public static func caption(_ g: Game) -> Caption? {
        if isUpset(g) { return .upset }
        if isBothRanked(g) { return .bothRanked }
        return nil
    }

    /// Coming up: UConn, ranked vs ranked (lower rank sum first), prominent, top-10 vs unranked;
    /// ties go to the earlier tip.
    public static func comingUpOrder(_ a: Game, _ b: Game) -> Bool { importanceOrder(a, b) }

    /// Tier, then lower rank sum (both ranked) or better best rank, then earlier start.
    public static func importanceOrder(_ a: Game, _ b: Game) -> Bool {
        let (ta, tb) = (tier(a), tier(b))
        if ta != tb { return ta < tb }
        let (ka, kb) = (rankKey(a), rankKey(b))
        if ka != kb { return ka < kb }
        return a.start < b.start
    }

    private static func wouldBeUpset(winner: Competitor, loser: Competitor) -> Bool {
        guard let loserRank = loser.rank else { return false }
        guard let winnerRank = winner.rank else { return true }
        return winnerRank - loserRank >= upsetRankGap
    }

    private static func isTopTenVsUnranked(_ g: Game) -> Bool {
        switch (g.home.rank, g.away.rank) {
        case let (r?, nil), let (nil, r?): return r <= 10
        default: return false
        }
    }

    /// Smaller is more important. Unranked counts as 26.
    private static func rankKey(_ g: Game) -> Int {
        let ranks = g.competitors.map { $0.rank ?? 26 }
        return isBothRanked(g) ? ranks.reduce(0, +) : ranks.min() ?? 26
    }
}
