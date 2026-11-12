import AppKit
import CBBCore
import CBBUI
import SwiftUI
import WidgetKit

struct BoardEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot?
}

struct Provider: TimelineProvider {
    static let refresh: TimeInterval = 15 * 60
    static let liveRefresh: TimeInterval = 5 * 60

    let store = SnapshotStore(directory: SnapshotStore.defaultDirectory)

    func placeholder(in context: Context) -> BoardEntry {
        BoardEntry(date: .now, snapshot: store.load())
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (BoardEntry) -> Void) {
        if let cached = store.load() {
            completion(BoardEntry(date: .now, snapshot: cached))
            return
        }
        Task { completion(BoardEntry(date: .now, snapshot: await fetch(now: .now))) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<BoardEntry>) -> Void) {
        Task {
            let now = Date()
            let snapshot = await fetch(now: now) ?? store.load()
            let isLive = snapshot.map { BoardBuilder.build($0.inputs, now: now).allGames.contains { $0.state == .live } } ?? false
            let next = now.addingTimeInterval(isLive ? Self.liveRefresh : Self.refresh)
            // Extra entries flip ticket states (soon/open/closed) on time, between fetches.
            let dates = [now] + TicketSchedule.boundaries(after: now, within: next.timeIntervalSince(now))
            completion(Timeline(entries: dates.map { BoardEntry(date: $0, snapshot: snapshot) }, policy: .after(next)))
        }
    }

    /// Fetches, caches the snapshot and logos; nil when the network or ESPN fails.
    private func fetch(now: Date) async -> Snapshot? {
        guard let inputs = try? await ESPNClient().fetchInputs(now: now) else { return nil }
        let snapshot = Snapshot(inputs: inputs, fetchedAt: now)
        try? store.save(snapshot)
        let board = BoardBuilder.build(inputs, now: now)
        await store.cacheLogos(for: board.teamIDs, session: .shared)
        return snapshot
    }
}

struct BoardEntryView: View {
    let entry: BoardEntry
    let store = SnapshotStore(directory: SnapshotStore.defaultDirectory)

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                BoardView(
                    board: BoardBuilder.build(snapshot.inputs, now: entry.date),
                    logo: { store.logo($0, dark: $1).flatMap(NSImage.init(data:)) },
                    updatedAt: snapshot.fetchedAt,
                    showUpdated: SnapshotStore.isStale(snapshot, now: entry.date)
                )
            } else {
                PlaceholderView(message: "Couldn't load scores")
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

@main
struct CBBWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CBBBoard", provider: Provider()) { entry in
            BoardEntryView(entry: entry)
        }
        .configurationDisplayName("College Basketball")
        .description("UConn, the big games around the top 25, and student ticket claims.")
        .supportedFamilies([.systemExtraLarge])
    }
}
