import Foundation
import Testing
@testable import CBBCore

@Test func upsets() {
    #expect(BigGames.isUpset(game("2641", 16, 84, "356", 3, 78, .final)))   // #16 over #3: 13 places
    #expect(BigGames.isUpset(game("2382", nil, 74, "12", 7, 70, .final)))   // unranked over ranked
    #expect(!BigGames.isUpset(game("127", 5, 79, "150", 2, 73, .final)))    // #5 over #2: only 3 places
    #expect(!BigGames.isUpset(game("2305", 15, 89, "96", 24, 69, .final)))  // better rank won
    #expect(!BigGames.isUpset(game("2382", nil, 74, "12", 7, 70, .live)))   // not final yet
    #expect(BigGames.caption(game("2641", 16, 84, "356", 3, 78, .final)) == .upset)
    #expect(BigGames.caption(game("127", 5, 79, "150", 2, 73, .final)) == .bothRanked)
    #expect(BigGames.caption(game("57", 1, 81, "52", nil, 72, .final)) == nil)
}

@Test func prominentIgnoresRank() {
    #expect(BigGames.isProminent(game("150", nil, nil, "153", nil, nil, .pre)))   // unranked Duke–UNC
    #expect(BigGames.qualifiesForComingUp(game("150", nil, nil, "153", nil, nil, .pre)))
    #expect(BigGames.qualifiesForScores(game("150", nil, nil, "153", nil, nil, .pre)))
    #expect(!BigGames.isProminent(game("150", 2, nil, "2565", nil, nil, .pre)))
}

@Test func comingUpNeedsTopTenAgainstUnranked() {
    #expect(BigGames.qualifiesForComingUp(game("57", 1, nil, "2771", nil, nil, .pre)))
    #expect(BigGames.qualifiesForComingUp(game("2771", nil, nil, "57", 10, nil, .pre)))
    #expect(!BigGames.qualifiesForComingUp(game("2390", 17, nil, "2453", nil, nil, .pre)))
    #expect(BigGames.qualifiesForScores(game("2390", 17, nil, "2453", nil, nil, .pre)))
    #expect(!BigGames.qualifiesForScores(game("52", nil, nil, "2083", nil, nil, .pre)))
    #expect(BigGames.qualifiesForComingUp(game("41", nil, nil, "194", nil, nil, .pre)))  // UConn always
}

@Test func upsetInProgressNeedsSecondHalf() {
    #expect(BigGames.isUpsetInProgress(game("2382", nil, 40, "12", 7, 35, .live, period: 2)))
    #expect(!BigGames.isUpsetInProgress(game("2382", nil, 40, "12", 7, 35, .live, period: 1)))
    #expect(!BigGames.isUpsetInProgress(game("2382", nil, 30, "12", 7, 35, .live, period: 2)))  // favourite leads
}

@Test func blowouts() {
    #expect(BigGames.isBlowout(game("26", 9, 106, "2029", nil, 37, .final)))
    #expect(!BigGames.isBlowout(game("26", 9, 80, "2029", nil, 70, .final)))
    #expect(!BigGames.isBlowout(game("127", 5, 99, "150", 2, 70, .final)))   // both ranked: not a blowout of an unranked team
}

@Test func tiersAndOrdering() {
    let uconn = game("41", 4, nil, "194", nil, nil, .pre)
    let rr = game("150", 2, nil, "356", 3, nil, .pre)          // sum 5
    let rr2 = game("2633", 11, nil, "127", 5, nil, .pre)       // sum 16
    let prom = game("150", nil, nil, "153", nil, nil, .pre)
    let top = game("57", 1, nil, "2771", nil, nil, .pre)
    #expect([top, prom, rr2, rr, uconn].sorted(by: BigGames.comingUpOrder) == [uconn, rr, rr2, prom, top])
    #expect(BigGames.tier(game("2382", nil, 40, "12", 7, 35, .live, period: 2)) == .upsetInProgress)
    #expect(BigGames.tier(game("57", 1, nil, "2771", nil, nil, .pre)) == .rankedVsUnranked)
    #expect(BigGames.tier(game("52", nil, nil, "2083", nil, nil, .pre)) == .other)
    let early = game("2633", 11, nil, "127", 5, nil, .pre, start: et("2026-11-12 12:00"))
    let late = game("2633", 11, nil, "127", 5, nil, .pre, start: et("2026-11-12 21:00"))
    #expect([late, early].sorted(by: BigGames.importanceOrder) == [early, late])
    let r1 = game("57", 1, nil, "2771", nil, nil, .pre)
    let r22 = game("238", 22, nil, "2504", nil, nil, .pre, start: et("2026-11-12 12:00"))
    #expect([r22, r1].sorted(by: BigGames.importanceOrder) == [r1, r22])
}
