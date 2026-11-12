// Renders the widget's view to a PNG, for checking the layout without installing the widget.
//
//   swift run cbb-render <out.png> [--live] [--now <ISO8601>] [--fetched <ISO8601>] [--light] [--placeholder]
//
// Without --live, builds from the test fixtures (run from the repo root) at --now
// (default 2026-11-12T20:00:00Z, 3 PM Eastern). --fetched sets the snapshot time, so a value well
// before --now shows the "Updated …" note.
import AppKit
import CBBCore
import CBBUI
import Foundation
import SwiftUI

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: cbb-render <out.png> [--live] [--now ISO] [--fetched ISO] [--light] [--placeholder]\n".utf8))
    exit(2)
}
let out = URL(fileURLWithPath: args[1])
func flag(_ name: String) -> Bool { args.contains(name) }
func option(_ name: String) -> String? {
    args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
}
func iso(_ s: String) -> Date {
    guard let d = ISO8601DateFormatter().date(from: s) else { fatalError("bad date \(s)") }
    return d
}

let live = flag("--live")
let now = live ? Date() : iso(option("--now") ?? "2026-11-12T20:00:00Z")
let fetchedAt = option("--fetched").map(iso) ?? now

func fixture(_ name: String) throws -> Data {
    try Data(contentsOf: URL(fileURLWithPath: "Tests/CBBCoreTests/Fixtures/\(name).json"))
}

let inputs: BoardInputs
if live {
    inputs = try await ESPNClient().fetchInputs(now: now)
} else {
    let men = try ESPNDecoder.schedule(fixture("men_schedule_41"), league: .men)
    let women = try ESPNDecoder.schedule(fixture("women_schedule_41"), league: .women)
    inputs = BoardInputs(
        menScoreboard: try ESPNDecoder.scoreboard(fixture("men_scoreboard_20261110"), league: .men)
            + ESPNDecoder.scoreboard(fixture("men_scoreboard_20261113"), league: .men),
        menSchedule: men.games, menRecord: men.record,
        womenSchedule: women.games, womenToday: []
    )
}
let snapshot = Snapshot(inputs: inputs, fetchedAt: fetchedAt)
let board = BoardBuilder.build(inputs, now: now)

let store = SnapshotStore(directory: FileManager.default.temporaryDirectory.appending(path: "cbb-render-cache"))
await store.cacheLogos(for: board.teamIDs, session: .shared)

let light = flag("--light")
let content: AnyView = flag("--placeholder")
    ? AnyView(PlaceholderView(message: "Couldn't load scores"))
    : AnyView(BoardView(
        board: board,
        logo: { store.logo($0, dark: $1).flatMap(NSImage.init(data:)) },
        updatedAt: snapshot.fetchedAt,
        showUpdated: SnapshotStore.isStale(snapshot, now: now)
    ))

let widget = content
    .padding(16)
    .frame(width: BoardView.size.width, height: BoardView.size.height)
    .background(light ? Color(white: 0.97) : Color(white: 0.17))
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    .padding(28)
    .background(LinearGradient(colors: light ? [.white, Color(white: 0.85)] : [Color(red: 0.23, green: 0.34, blue: 0.5), Color(red: 0.1, green: 0.13, blue: 0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
    .environment(\.colorScheme, light ? .light : .dark)
    .environment(\.cbbLinksEnabled, false)

let renderer = ImageRenderer(content: widget)
renderer.scale = 2
guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
      let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
    fatalError("render failed")
}
try png.write(to: out)
print("wrote \(out.path)")
