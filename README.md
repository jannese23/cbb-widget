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
