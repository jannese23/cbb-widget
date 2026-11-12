import Foundation
import Testing
@testable import CBBCore

@Test func ticketBoundariesGetEntriesEvenIfTheReloadIsLate() {
    // 9 PM Fri Nov 13: Rider turns "soon" at 10 PM, an hour past a 15-minute reload.
    let dates = TimelinePlan.entryDates(now: et("2026-11-13 21:00"))
    #expect(dates.first == et("2026-11-13 21:00"))
    #expect(dates.contains(et("2026-11-13 22:00")))
    #expect(dates == dates.sorted())
    #expect(dates.allSatisfy { $0 <= et("2026-11-14 21:00") })   // 24 h horizon
}
