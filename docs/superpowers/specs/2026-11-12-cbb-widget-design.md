# College Basketball Desktop Widget — Design

2026-11-12 · owner: Jackson Annese · status: draft for approval

## Why

Jackson is a UConn student and fan. They have notifications for UConn but not for the rest of college
basketball, and they want a quick glance at how UConn is faring compared with the other top teams, and
which results elsewhere could move the rankings around UConn. Today that means sifting through full
scoreboards full of irrelevant games. The widget is a **filtered scoreboard centred on UConn** that sits
on the macOS desktop next to their Photos and Calendar widgets. It also tells them when a **student ticket
claim** is about to open or is open, so they don't miss one.

Success: one glance at the desktop answers "how is UConn doing, what happened to the other top teams,
what big games are coming, and do I need to claim a ticket?" It shows nothing they have to skip past.

## Goals

1. UConn men's: next game, last result, record and AP rank; the live score when a game is on.
2. UConn women's: games against **ranked** opponents only (women's AP poll).
3. Big games coming up: ranked vs ranked, top-ranked vs unranked, and prominent matchups between
   big-name programs, even when both are unranked (e.g. Duke–UNC with both unranked).
4. Scores for today's relevant games, plus the latest ranked results.
5. Student ticket claims for the 2026–27 season: quiet, "opens soon" countdown, and "open now" states.
6. Looks like a native Apple widget (Apple Sports / Calendar style), not a custom-designed panel.

## Non-goals

- Play-by-play or second-by-second live scores. A glance every ~15 minutes is enough.
- Notifications, a settings UI, other sports, iOS, distributing the app to anyone else.
- Ticket claims for future seasons (they won't be a student). No scraping of the claim page: the
  schedule is built in.
- Claiming tickets for them. The widget only links to the claim site.

## Anti-goals (it fails even if it technically works)

- It fills up with games they don't care about (unranked vs unranked blowouts, minor programs).
- It looks like a web page or a "curated" dashboard rather than an Apple widget.
- It is blank or broken on a quiet day or when the network drops.

## Constraints

- **Machine:** macOS 26.6 (Tahoe), Xcode 27.2, Swift/SwiftUI. Signing identity available:
  "Apple Development: jackson.annese@icloud.com". It only needs to run on their Mac.
- **Platform:** a WidgetKit widget extension inside a minimal macOS host app. WidgetKit limits refresh
  (a budget of roughly every 15 minutes) and does not support `AsyncImage`: logos must be downloaded
  during the timeline fetch and handed to the view as image data.
- **Repo:** `~/Dev/Projects/cbb-widget`, its own git repo, local only (no remote unless they ask).
- **Data:** ESPN's free public site API (no key, unofficial, can change without notice). Endpoints
  verified working on 2026-11-12:
  - Scoreboard: `https://site.api.espn.com/apis/site/v2/sports/basketball/{league}/scoreboard?groups=50&limit=400&dates=YYYYMMDD`
    where `{league}` is `mens-college-basketball` or `womens-college-basketball`. Each competitor has
    `curatedRank.current` (AP rank; 99 means unranked), `score`, `homeAway`, team `id`/`abbreviation`.
  - Rankings: `.../{league}/rankings` (first entry is the AP Top 25).
  - Team schedule: `.../{league}/teams/41/schedule` (UConn is team id 41 in both leagues).
  - Logos: `https://a.espncdn.com/i/teamlogos/ncaa/500-dark/{teamId}.png` (dark-background variant;
    `500/` is the standard one).

## Layout (decided: option B, one extra-large widget)

Only the `systemExtraLarge` family. Two columns. Reference mockup with real data from 2026-11-12:
`docs/mockups/2026-11-12-layouts.html`, option B. That mockup is the look to match: glass/system
background, SF system font, team logos, two-line stacked games (logo, small grey rank, abbreviation,
score; status on the right, vertically centred), losing team greyed out, thin dividers, small grey
section labels, grey captions under the status, orange "Upset" caption, red live clock. Tickets look
like Calendar events (coloured bar on the left).

### Left column: UConn

1. **Header:** UConn logo, "UConn", men's record and AP rank (e.g. "3–0 · AP 4").
2. **Men's block:** UConn logo vs opponent logo, opponent name, day/time and arena of the next game;
   last result on the right ("W 83–41 / Wagner"). While a UConn men's game is live, this block shows
   the live score and clock instead.
3. **Women's line:** one line for UConn women vs a ranked opponent (women's AP rank). Shows the live
   score if such a game is live; otherwise the next ranked-opponent game if it's within 7 days;
   otherwise the most recent ranked-opponent result if it's within 3 days; otherwise hidden. Games
   against unranked opponents never appear.
4. **Ticket claim row(s):** see "Ticket claims" below.
5. **Coming up:** big games in the next 7 days that aren't today, best first (see "What counts").
   As many as fit. Leaves out the UConn game already shown in the men's block; later UConn games
   still appear (*my call*).

### Right column: scores

1. **Today** (header shows today's date): every game today that qualifies (see "What counts").
   Live first, then upcoming by tip time, then finals.
   **When more qualify than fit** (busy Saturdays), choose which to keep by importance first
   (decided by Jackson): UConn, then ranked vs ranked (lower rank sum first), then prominent
   matchups, then upsets in progress (an unranked or much lower-ranked team leading in the second
   half), then ranked vs unranked (higher-ranked team first). The kept games are then displayed in
   the live / upcoming / final order above. Today never takes the last two rows of the column:
   Latest always keeps at least two rows when it has results.
2. **Latest:** fills the remaining space with ranked results from the previous 2 days. Order: upsets,
   then ranked vs ranked, then prominent matchups, then everything else. Blowouts of unranked teams by
   ranked teams go last.

Both columns show as many rows as fit and drop the rest; nothing scrolls.

## What counts as a big game

Men's college basketball (Division I), except where stated. A game qualifies if any of:

- it involves UConn (men's);
- both teams are AP-ranked ("Both ranked" caption);
- a top-ranked team plays an unranked team. For **Coming up**, only top-10 teams vs unranked.
  For **Today/Latest**, any ranked team, so they can see how ranked teams fared;
- it's a **prominent matchup**: both teams are on the built-in list of big-name programs. Duke, North
  Carolina, Kentucky, Kansas, UCLA, Indiana, Michigan State, Villanova, Louisville, Syracuse, Arizona,
  Gonzaga. Ranks don't matter here. The list lives in one source file so it's easy to edit later.

They explicitly dropped a separate named-rivalries list. No "Rivalry" caption.

**Upset** (orange caption): an unranked team beats a ranked team, or a ranked team beats one ranked
8 or more places higher.

Priority order for **Coming up**: UConn games; then ranked vs ranked (lower sum of the two ranks
first); then prominent matchups; then top-10 vs unranked. Ties go to the earlier tip.

## Ticket claims

Source: <https://uconnhuskies.com/sports/2018/6/12/student-basketball-tickets> (read 2026-11-12).
Built into the app as a fixed list for the 2026–27 season only.

Rules from the page: a claim **opens at 10:00 PM** on its open date and **closes at 11:59 PM** on its
close date, US Eastern time. Claim at UConnTickets.com. Include **all men's home games** and only the
**women's games at Gampel (GP)**.

States, evaluated against now:
- **Open** (green bar): now is between open and close. Shows the game, "Claim open", and the close time.
- **Soon** (yellow bar): opens within the next 48 hours. Shows the game and a live countdown to the
  open time (use SwiftUI's relative/timer `Text` so it ticks without a refresh).
- **Quiet** (grey bar): otherwise, show only the single next claim and the day it opens.
- Show every claim that's Open or Soon (overlaps happen, e.g. Kansas 11/28 and Delaware St 11/29).
  If none, show the one Quiet row. After the last claim closes, hide the row entirely.
- Clicking a ticket row opens `https://uconntickets.com` in the browser.

Each row shows: "Men's vs Rider", "Gampel · Mon, Nov 30" (arena: GP = Gampel, PBA = PeoplesBank).

### Men's (all)

| Game date | Opponent | Arena | Opens (10 PM) | Closes (11:59 PM) |
|---|---|---|---|---|
| 2026-10-27 | Purdue | PBA | 2026-10-15 | 2026-10-18 |
| 2026-11-02 | Gardner-Webb | PBA | 2026-10-18 | 2026-10-21 |
| 2026-11-09 | Wagner | GP | 2026-10-24 | 2026-10-27 |
| 2026-11-13 | Ohio State | PBA | 2026-10-28 | 2026-10-31 |
| 2026-11-30 | Rider | GP | 2026-11-15 | 2026-11-18 |
| 2026-12-08 | Mississippi Valley St | GP | 2026-11-22 | 2026-11-25 |
| 2026-12-12 | Kansas | GP | 2026-11-28 | 2026-12-01 |
| 2026-12-15 | Delaware State | PBA | 2026-11-29 | 2026-12-02 |
| 2026-12-23 | Georgetown | PBA | 2026-12-07 | 2026-12-10 |
| 2027-01-06 | DePaul | GP | 2026-12-21 | 2026-12-24 |
| 2027-01-12 | Marquette | GP | 2026-12-27 | 2026-12-30 |
| 2027-01-16 | Xavier | GP | 2026-12-30 | 2027-01-02 |
| 2027-01-23 | Butler | PBA | 2027-01-08 | 2027-01-11 |
| 2027-02-03 | Villanova | PBA | 2027-01-17 | 2027-01-20 |
| 2027-02-07 | Creighton | PBA | 2027-01-22 | 2027-01-25 |
| 2027-02-17 | Seton Hall | GP | 2027-02-01 | 2027-02-04 |
| 2027-02-27 | Providence | GP | 2027-02-11 | 2027-02-14 |
| 2027-03-02 | St. John's | PBA | 2027-02-14 | 2027-02-17 |

### Women's (Gampel only)

| Game date | Opponent | Arena | Opens (10 PM) | Closes (11:59 PM) |
|---|---|---|---|---|
| 2026-10-25 | Army | GP | 2026-10-14 | 2026-10-17 |
| 2026-11-08 | Iowa | GP | 2026-10-22 | 2026-10-25 |
| 2026-12-02 | UNLV | GP | 2026-11-16 | 2026-11-19 |
| 2026-12-16 | Creighton | GP | 2026-12-01 | 2026-12-04 |
| 2027-01-28 | DePaul | GP | 2027-01-14 | 2027-01-17 |
| 2027-02-10 | Villanova | GP | 2027-01-25 | 2027-01-28 |
| 2027-02-13 | Xavier | GP | 2027-01-27 | 2027-01-30 |
| 2027-02-28 | Butler | GP | 2027-02-12 | 2027-02-15 |

## Refresh and failure behaviour

- Fetch on each timeline reload; ask for a reload ~15 minutes out normally, ~5 minutes out while any
  shown game is live (the system may throttle this; that's accepted).
- The ticket section is computed locally, so it stays correct offline. Add timeline entries at each
  claim open/close boundary so states flip on time without a fetch.
- If a fetch fails, keep showing the last good data with a small grey "Updated 3:12 PM" note. Never
  show a blank widget. Cache the last good snapshot and downloaded logos on disk.
- Times display in the Mac's local time zone. Ticket open/close times are defined in US Eastern.

## Clicks

- Ticket row → `https://uconntickets.com`.
- A game row → that game's ESPN page (*my call*).
- Elsewhere → opens the host app (*my call*). The host app can be bare: a window that shows the same
  view at a larger size with a "Refresh" button is enough.

## Calls I made (not discussed with Jackson; they can override)

- Ranks are the **AP** Top 25 (`curatedRank`, which defaults to AP), men's and women's.
- "Coming up" looks 7 days ahead; "Latest" looks back 2 days; the women's line windows (7 days ahead,
  3 days back).
- The upset threshold (unranked over ranked, or 8+ rank places).
- Top-10 cutoff for unranked opponents in "Coming up".
- The big-name program list above (they dropped the rivalry list but kept "prominent unranked matchups").
- Game rows link to ESPN.
- The Purdue (10/27) and other early claims are in the list for completeness even though they're past;
  past claims simply never show.

## Left to the builder

- Project structure and tooling (e.g. hand-made Xcode project vs XcodeGen), and app/bundle names.
- Model types, the parsing approach, caching location, and how logos are fetched and resized.
- Exact fonts, spacing and colours, within the mockup's look and Apple's widget conventions. It must
  also look right in macOS's tinted/unfocused desktop widget mode (`widgetAccentable`, system
  container background) and in light mode.
- Testing approach. The selection, ordering, upset and ticket-state logic should be unit-tested
  against saved ESPN JSON fixtures and fixed clocks.
- Truncation rules for long team names (use ESPN abbreviations in game rows).
