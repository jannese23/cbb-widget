import AppKit
import CBBCore
import CBBUI
import SwiftUI
import WidgetKit

@MainActor @Observable
final class BoardModel {
    var snapshot: Snapshot?
    var loading = false
    var failed = false

    let store = SnapshotStore(directory: SnapshotStore.defaultDirectory)

    init() {
        snapshot = store.load()
    }

    func refresh() async {
        loading = true
        defer { loading = false }
        let now = Date()
        do {
            let inputs = try await ESPNClient().fetchInputs(now: now)
            let fresh = Snapshot(inputs: inputs, fetchedAt: now)
            try? store.save(fresh)
            await store.cacheLogos(for: BoardBuilder.build(inputs, now: now).teamIDs, session: .shared)
            snapshot = fresh
            failed = false
        } catch {
            failed = true
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct ContentView: View {
    @State private var model = BoardModel()

    var body: some View {
        Group {
            if let snapshot = model.snapshot {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    BoardView(
                        board: BoardBuilder.build(snapshot.inputs, now: context.date),
                        logo: { model.store.logo($0, dark: $1).flatMap(NSImage.init(data:)) },
                        updatedAt: snapshot.fetchedAt,
                        showUpdated: model.failed || SnapshotStore.isStale(snapshot, now: context.date)
                    )
                }
            } else if model.loading {
                ProgressView()
            } else {
                PlaceholderView(message: "Couldn't load scores")
            }
        }
        .padding(16)
        .frame(width: BoardView.size.width, height: BoardView.size.height)
        .toolbar {
            Button {
                Task { await model.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(model.loading)
        }
        .task { await model.refresh() }
    }
}

@main
struct CBBApp: App {
    var body: some Scene {
        WindowGroup("College Basketball") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
