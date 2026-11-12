import Foundation
import Testing
@testable import CBBCore

@Test func realWeekOfNov12() throws {
    let b = BoardBuilder.build(inputsFromFixtures(), now: et("2026-11-12 15:00"))
    #expect(b.uconn.record == "3-0" && b.uconn.rank == 4)
    #expect(b.uconn.live == nil)
    #expect(b.uconn.next?.opponent(of: "41")?.team.id == "194")
    #expect(b.uconn.last?.opponent(of: "41")?.team.location == "Wagner")
    #expect(b.women?.opponent(of: "41")?.team.id == "194")             // at #17 Ohio State tonight
    #expect(b.tickets.map(\.claim.opponent) == ["Rider"])
    #expect(b.latest.first.map(BigGames.isUpset) == true)                // #16 TTU over #3 Illinois leads
    #expect(!b.comingUp.contains { $0.id == b.uconn.next?.id })
    #expect(b.today.isEmpty)                                             // no Nov 12 scoreboard in the fixtures
    #expect(b.today.count + b.latest.count <= Slots.rightColumn)
}

@Test func busyDayKeepsImportantGamesAndTwoLatest() {
    let b = BoardBuilder.build(busyInputs(), now: et("2026-12-05 11:00"))
    #expect(b.today.count == 4 && b.latest.count == 2)
    #expect(b.today.contains { BigGames.isBothRanked($0) })
    #expect(b.today.last.map(BigGames.isBothRanked) == true)            // shown in tip order: 9 PM last
}

@Test func lateGameCrossingMidnightStaysLive() {
    let late = game("150", 2, 70, "356", 3, 68, .live, period: 2, start: et("2026-11-17 22:00"))
    let b = BoardBuilder.build(inputs(menScoreboard: [late]), now: et("2026-11-18 00:30"))
    #expect(b.today.map(\.id) == [late.id] && b.latest.isEmpty)
}

@Test func postponedNeverShows() {
    let p = game("150", 2, nil, "356", 3, nil, .postponed, start: et("2026-11-12 19:00"))
    let b = BoardBuilder.build(inputs(menScoreboard: [p]), now: et("2026-11-12 20:00"))
    #expect(b.today.isEmpty && b.latest.isEmpty && b.comingUp.isEmpty)
}

@Test func womenUnrankedOpponentHidden() {
    let w = game("41", 4, nil, "2550", nil, nil, .pre, league: .women, start: et("2026-11-20 20:00"))
    #expect(BoardBuilder.build(inputs(womenSchedule: [w]), now: et("2026-11-18 12:00")).women == nil)
}

@Test func womenLinePrefersLiveThenNextThenRecent() {
    let recent = game("41", 4, 91, "2294", 10, 79, .final, league: .women, start: et("2026-11-08 14:00"))
    let next = game("97", 7, nil, "41", 4, nil, .pre, league: .women, start: et("2026-11-15 17:30"))
    let far = game("97", 7, nil, "41", 4, nil, .pre, league: .women, start: et("2026-11-25 17:30"))
    let live = game("194", 17, 30, "41", 4, 33, .live, league: .women, start: et("2026-11-12 18:30"))
    #expect(BoardBuilder.build(inputs(womenSchedule: [recent, next], womenToday: [live]), now: et("2026-11-12 19:00")).women == live)
    #expect(BoardBuilder.build(inputs(womenSchedule: [recent, next]), now: et("2026-11-12 19:00")).women == next)
    #expect(BoardBuilder.build(inputs(womenSchedule: [recent, far]), now: et("2026-11-10 12:00")).women == recent)
    #expect(BoardBuilder.build(inputs(womenSchedule: [recent, far]), now: et("2026-11-12 19:00")).women == nil)
}

@Test func uconnLiveComesFromScoreboard() {
    let scheduled = game("41", 4, nil, "194", nil, nil, .pre, start: et("2026-11-13 19:30"))
    let live = game("41", 4, 40, "194", nil, 38, .live, start: et("2026-11-13 19:30"))
    let b = BoardBuilder.build(inputs(menScoreboard: [live], menSchedule: [scheduled]), now: et("2026-11-13 20:15"))
    #expect(b.uconn.live == live)
}

@Test func extraTicketRowsShrinkComingUp() {
    let b = BoardBuilder.build(manyBigGamesInputs(), now: et("2026-11-29 23:00"))  // Kansas, Delaware St open; Creighton soon
    #expect(b.tickets.count == 3 && b.comingUp.count == 1)
    let quieter = BoardBuilder.build(manyBigGamesInputs(), now: et("2026-11-27 12:00"))  // only Kansas, soon
    #expect(quieter.tickets.count == 1 && quieter.comingUp.count == 3)
}

@Test func latestPutsUpsetsFirstAndBlowoutsLast() {
    let blowout = game("26", 9, 106, "2029", nil, 37, .final, start: et("2026-11-11 21:00"))
    let plain = game("57", 1, 81, "52", nil, 72, .final, start: et("2026-11-11 19:00"))
    let rr = game("127", 5, 79, "150", 2, 73, .final, start: et("2026-11-10 19:00"))
    let upset = game("2641", 16, 84, "356", 3, 78, .final, start: et("2026-11-10 20:00"))
    let b = BoardBuilder.build(inputs(menScoreboard: [blowout, plain, rr, upset]), now: et("2026-11-12 10:00"))
    #expect(b.latest == [upset, rr, plain, blowout])
}
