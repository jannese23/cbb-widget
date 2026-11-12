import Foundation
import Testing
@testable import CBBCore

@Test func parsesDatesWithAndWithoutSeconds() {
    #expect(ESPNDecoder.parseDate("2026-11-13T02:00Z") == Date(timeIntervalSince1970: 1794535200))
    #expect(ESPNDecoder.parseDate("2026-11-13T02:00:00Z") == Date(timeIntervalSince1970: 1794535200))
    #expect(ESPNDecoder.parseDate("not a date") == nil)
}

@Test func decodesFinalScoreboard() throws {
    let games = try ESPNDecoder.scoreboard(fixture("men_scoreboard_20261110"), league: .men)
    let g = try #require(games.first { $0.involves("150") && $0.involves("127") })
    #expect(g.state == .final && g.statusText == "Final")
    #expect(g.home.team.abbreviation == "DUKE" && g.home.rank == 2 && g.home.score == 73)
    #expect(g.away.rank == 5 && g.away.score == 79)
    #expect(g.winner?.team.id == "127")
    #expect(g.loser?.team.id == "150")
    #expect(g.link?.absoluteString.hasPrefix("https://www.espn.com/mens-college-basketball/game/") == true)
    #expect(games.contains { $0.home.rank == nil || $0.away.rank == nil })   // 99 → nil
}

@Test func decodesUpcomingScoreboard() throws {
    let g = try #require(ESPNDecoder.scoreboard(fixture("men_scoreboard_20261113"), league: .men).first { $0.involves("41") })
    #expect(g.state == .pre && g.home.score == nil && g.opponent(of: "41")?.team.id == "194")
    #expect(g.start == ESPNDecoder.parseDate("2026-11-14T00:30Z"))
    #expect(g.venue == "PeoplesBank Arena")
}

@Test func decodesScheduleWithRecordAndObjectScores() throws {
    let (record, games) = try ESPNDecoder.schedule(fixture("men_schedule_41"), league: .men)
    #expect(record == "3-0")
    let wagner = try #require(games.first { $0.opponent(of: "41")?.team.location == "Wagner" })
    #expect(wagner.state == .final && wagner.home.score == 83 && wagner.away.score == 41)
}

@Test func decodesWomenScheduleRanks() throws {
    let (_, games) = try ESPNDecoder.schedule(fixture("women_schedule_41"), league: .women)
    let osu = try #require(games.first { $0.opponent(of: "41")?.team.id == "194" })
    #expect(osu.league == .women && osu.opponent(of: "41")?.rank == 17)
}

@Test func toleratesOddEvents() throws {
    let games = try ESPNDecoder.scoreboard(fixture("men_scoreboard_live"), league: .men)
    #expect(games.count == 3)
    #expect(games.contains { $0.state == .live && $0.statusText == "2nd 4:20" && $0.period == 2 })
    #expect(games.contains { $0.state == .postponed })
    #expect(games.contains { $0.venue == nil && $0.away.rank == nil && $0.away.score == nil })
}

@Test func skipsMalformedEventInsteadOfFailingTheDay() throws {
    let json = #"{"events":[{"id":"1"},{"id":"2","date":"2026-11-13T02:00Z","competitions":[]}]}"#
    #expect(try ESPNDecoder.scoreboard(Data(json.utf8), league: .men).isEmpty)
    #expect(throws: (any Error).self) { try ESPNDecoder.scoreboard(Data("[]".utf8), league: .men) }
}
