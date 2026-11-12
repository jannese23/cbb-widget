# CBB widget — Claude Code guidance

Personal macOS desktop widget for a UConn student. Read `README.md` first (how it works, status,
open items), then the design `docs/superpowers/specs/2026-11-12-cbb-widget-design.md`, which is the
authority on behaviour. The build plan is `docs/superpowers/plans/2026-11-12-cbb-widget.md`.

## Working here

- Logic changes go in `Sources/CBBCore` with tests first (`swift test`, Swift Testing). Fixtures are
  real ESPN responses from 2026-11-10/13; tests use fixed clocks via `et("yyyy-MM-dd HH:mm")`.
- Check layout changes with `swift run cbb-render <out.png>` (add `--live`, `--light`) and look at
  the PNG. `ImageRenderer` can't draw `Link`, so the renderer turns links off (`cbbLinksEnabled`).
- `CBB.xcodeproj` is generated: edit `project.yml`, then `xcodegen generate`. Build/install commands
  are in the README; signing team `A4U8TCFTCZ`, automatic.
- Reinstall with `ditto` over `~/Applications/CBB.app`. The user's file-safety hook blocks
  `rm -rf` outside the repo; don't work around it.
- In zsh, `log` is a builtin: use `/usr/bin/log show ...` for the unified log.
- The shell has no screen-recording permission, so `screencapture -l` of the app fails; ask the
  user for a screenshot of the real widget.
- Widget clicks are routed through the host app (see README "Clicks"); keep `AppDelegate` intact.
- Remote: `github.com/jannese23/cbb-widget` (private). Work on a branch; the user merges.
