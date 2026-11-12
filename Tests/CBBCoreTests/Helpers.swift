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

func inputs(menScoreboard: [Game] = [], menSchedule: [Game] = [], womenSchedule: [Game] = [],
            womenToday: [Game] = []) -> BoardInputs {
    BoardInputs(menScoreboard: menScoreboard, menSchedule: menSchedule, menRecord: nil,
                womenSchedule: womenSchedule, womenToday: womenToday)
}

func inputsFromFixtures() -> BoardInputs {
    let men = try! ESPNDecoder.schedule(fixture("men_schedule_41"), league: .men)
    let women = try! ESPNDecoder.schedule(fixture("women_schedule_41"), league: .women)
    let scoreboard = try! ESPNDecoder.scoreboard(fixture("men_scoreboard_20261110"), league: .men)
        + ESPNDecoder.scoreboard(fixture("men_scoreboard_20261113"), league: .men)
    return BoardInputs(menScoreboard: scoreboard, menSchedule: men.games, menRecord: men.record,
                       womenSchedule: women.games, womenToday: [])
}

/// Sat Dec 5: ten ranked-vs-unranked games at noon, #3 vs #8 at 9 PM, three ranked finals on Friday.
func busyInputs() -> BoardInputs {
    var games = (1...10).map { i in
        game("r\(i)", 10 + i, nil, "u\(i)", nil, nil, .pre, start: et("2026-12-05 12:00"))
    }
    games.append(game("356", 3, nil, "248", 8, nil, .pre, start: et("2026-12-05 21:00")))
    games += (1...3).map { (i: Int) in
        game("f\(i)", i, 80, "g\(i)", nil, 70, .final, start: et("2026-12-04 19:00"))
    }
    return inputs(menScoreboard: games)
}

/// Five ranked-vs-ranked games between Mon Nov 30 and Sat Dec 5.
func manyBigGamesInputs() -> BoardInputs {
    inputs(menScoreboard: (0..<5).map { i in
        game("a\(i)", 2 * i + 1, nil, "b\(i)", 2 * i + 2, nil, .pre,
             start: et("2026-11-30 19:00").addingTimeInterval(Double(i) * 86400))
    })
}
