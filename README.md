# College Basketball desktop widget

An extra-large macOS desktop widget: UConn (men's games, women's games against ranked teams),
2026–27 student ticket claims, big games coming up, and today's and the latest ranked scores.
Data comes from ESPN's public site API. Design: `docs/superpowers/specs/2026-11-12-cbb-widget-design.md`.

## Layout

- `Sources/CBBCore`: models, ESPN decoding, big-game rules, ticket claims, board building, fetching and caching
- `Sources/CBBUI`: the SwiftUI view shared by the widget and the app
- `Sources/cbb-render`: renders the view to a PNG for layout checks
- `App/`, `Widget/`, `project.yml`: the host app and WidgetKit extension (XcodeGen)

## Develop

```bash
swift test
swift run cbb-render /tmp/cbb.png            # fixtures, Thu Nov 12 3 PM ET
swift run cbb-render /tmp/cbb.png --live     # today's real data
swift run cbb-render /tmp/cbb.png --light    # light appearance
```

Refresh the fixtures by re-running the `curl` commands in the plan (Task 1), then
`python3 -I scripts/make_fixtures.py Tests/CBBCoreTests/Fixtures`.

## Build and install

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project CBB.xcodeproj -scheme CBB -configuration Release -derivedDataPath build -allowProvisioningUpdates build
ditto build/Build/Products/Release/CBB.app ~/Applications/CBB.app
open ~/Applications/CBB.app
```

Then right-click the desktop → **Edit Widgets** → search "College Basketball" → add the extra-large size.
The app window shows the same board with a Refresh button that also reloads the widget.

## Tuning

- Big-name programs, upset gap and blowout margin: `Sources/CBBCore/BigGames.swift`
- Rows per column (`Slots`) and look-ahead/look-back windows: `Sources/CBBCore/BoardBuilder.swift`
- Claim schedule: `Sources/CBBCore/TicketClaims.swift`

## How it works

- **Refresh:** the widget fetches 13 ESPN URLs (men's scoreboards for today −2 … +7, both UConn
  schedules, today's women's scoreboard) every 15 min, or every 5 min while a shown game is live.
  macOS may throttle this. Ticket claim states are computed locally, with timeline entries 24 h
  ahead, so they flip on time even without a fetch.
- **Offline / ESPN changes:** the last good fetch is cached (`<Caches>/CBB/snapshot.json` in each
  process's sandbox container). A failed or unrecognisable response never overwrites it; the widget
  shows "Updated h:mm" once data is over 30 min old, and "Couldn't load scores" only with no cache.
- **Clicks:** on macOS a widget click doesn't open its link; the system launches `CBB.app` and hands
  it the URL. `AppDelegate` in `App/CBBApp.swift` forwards http(s) links to the browser, never opens
  a window for them, and quits again if the link is what launched it. Clicking empty widget space
  opens the app window (normal macOS behaviour).
- **Logos:** ESPN's `500-dark` (dark mode) and `500` (light mode) variants, resized to 64 px and cached.

## Status (2026-11-12)

Built, installed in `~/Applications`, widget added to the desktop and clicks confirmed working.
Design: `docs/superpowers/specs/2026-11-12-cbb-widget-design.md`. Build plan:
`docs/superpowers/plans/2026-11-12-cbb-widget.md`. Layout mockups: `docs/mockups/`.

Open items:
- Check the real widget's bottom row fits (the last check had the app window covering it); if it
  clips, lower `Slots.leftComingUp` / `Slots.rightColumn` and update the busy-day test.
- In the app window (not the widget), clickable text shows in the accent colour (blue).

Known minor issues, deferred from the final review:
- A failed fetch within 30 min of a good one shows no "Updated" note in the widget (the app does).
- While UConn is live, their following game is hidden from Coming up.
- The women's line can briefly disappear between tip-off and ESPN marking the game live.
- No midnight-Eastern timeline entry, so Today can show yesterday until the next reload.
- Venue shortening is hard-coded for Gampel and PeoplesBank; other long venues truncate.
- `placeholder(in:)` reads the cache instead of a static sample.
- First run downloads all logos at once; days +2…+7 could be fetched hourly to cut ESPN traffic.
