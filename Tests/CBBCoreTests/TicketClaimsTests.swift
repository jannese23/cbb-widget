import Foundation
import Testing
@testable import CBBCore

@Test func tableIsComplete() {
    #expect(TicketSchedule.all.filter { $0.squad == .men }.count == 18)
    #expect(TicketSchedule.all.filter { $0.squad == .women }.count == 8)
    #expect(TicketSchedule.all.allSatisfy { $0.squad == .men || $0.arena == .gampel })
    #expect(TicketSchedule.all.allSatisfy { $0.opens < $0.closes && $0.closes < $0.gameDay })
}

@Test func quietShowsOnlyNextClaim() {
    let rows = TicketSchedule.rows(at: et("2026-11-12 15:00"))
    #expect(rows.map(\.claim.opponent) == ["Rider"] && rows[0].state == .quiet)
    #expect(rows[0].claim.arena == .gampel && rows[0].claim.squad == .men)
}

@Test func soonWithin48Hours() {
    #expect(TicketSchedule.rows(at: et("2026-11-13 21:59")).first?.state == .quiet)
    #expect(TicketSchedule.rows(at: et("2026-11-13 22:00")).first?.state == .soon)
}

@Test func exactOpenAndCloseInstants() {
    #expect(TicketSchedule.rows(at: et("2026-11-15 21:59")).first { $0.claim.opponent == "Rider" }?.state == .soon)
    #expect(TicketSchedule.rows(at: et("2026-11-15 22:00")).first { $0.claim.opponent == "Rider" }?.state == .open)
    #expect(TicketSchedule.rows(at: et("2026-11-18 23:58")).first { $0.claim.opponent == "Rider" }?.state == .open)
    #expect(!TicketSchedule.rows(at: et("2026-11-18 23:59")).contains { $0.claim.opponent == "Rider" })
}

@Test func overlappingClaimsBothShow() {
    let rows = TicketSchedule.rows(at: et("2026-11-29 23:00"))   // women's Creighton opens 12/1 10 PM → soon
    #expect(rows.map(\.claim.opponent) == ["Kansas", "Delaware State", "Creighton"])
    #expect(rows.map(\.state) == [.open, .open, .soon])
    let menAndWomen = TicketSchedule.rows(at: et("2026-11-16 23:00"))   // Rider open + UNLV (women) open
    #expect(Set(menAndWomen.map(\.claim.opponent)) == ["Rider", "UNLV"])
}

@Test func dstHandled() throws {
    let purdue = try #require(TicketSchedule.all.first { $0.opponent == "Purdue" })
    #expect(purdue.opens == ESPNDecoder.parseDate("2026-10-16T02:00Z"))   // EDT
    let rider = try #require(TicketSchedule.all.first { $0.opponent == "Rider" })
    #expect(rider.opens == ESPNDecoder.parseDate("2026-11-16T03:00Z"))    // EST
    #expect(rider.closes == ESPNDecoder.parseDate("2026-11-19T04:59Z"))
}

@Test func seasonOver() { #expect(TicketSchedule.rows(at: et("2027-03-01 12:00")).isEmpty) }

@Test func boundaries() {
    let b = TicketSchedule.boundaries(after: et("2026-11-13 12:00"), within: 3 * 86400)
    #expect(b.contains(et("2026-11-13 22:00")) && b.contains(et("2026-11-15 22:00")))
    #expect(b == b.sorted() && b.allSatisfy { $0 > et("2026-11-13 12:00") })
    #expect(!b.contains(et("2026-11-18 23:59")))   // outside the window
}
