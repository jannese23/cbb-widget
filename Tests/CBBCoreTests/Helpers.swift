import Foundation
@testable import CBBCore

func fixture(_ name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
    return try! Data(contentsOf: url)
}

/// A wall-clock time in America/New_York, written "yyyy-MM-dd HH:mm".
func et(_ s: String) -> Date {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "America/New_York")
    f.dateFormat = "yyyy-MM-dd HH:mm"
    return f.date(from: s)!
}

func game(_ homeID: String, _ homeRank: Int?, _ homeScore: Int?,
          _ awayID: String, _ awayRank: Int?, _ awayScore: Int?,
          _ state: GameState, period: Int = 2, league: League = .men,
          start: Date = et("2026-11-12 19:00")) -> Game {
    Game(
        id: "\(homeID)-\(awayID)-\(start.timeIntervalSince1970)", league: league, start: start, state: state,
        period: period, statusText: state == .final ? "Final" : "", venue: nil,
        home: Competitor(team: Team(id: homeID, abbreviation: homeID, location: homeID), rank: homeRank, score: homeScore, isHome: true),
        away: Competitor(team: Team(id: awayID, abbreviation: awayID, location: awayID), rank: awayRank, score: awayScore, isHome: false),
        link: nil
    )
}
