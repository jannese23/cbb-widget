import Foundation

/// When the widget needs a fresh render without a fetch.
public enum TimelinePlan {
    /// How far ahead ticket-state entries are pre-scheduled. Independent of the reload policy,
    /// because WidgetKit throttles reloads and states must still flip on time.
    static let horizon: TimeInterval = 24 * 3600

    /// Now, plus every instant in the next 24 h when a ticket claim turns soon, opens or closes.
    public static func entryDates(now: Date) -> [Date] {
        [now] + TicketSchedule.boundaries(after: now, within: horizon)
    }
}
