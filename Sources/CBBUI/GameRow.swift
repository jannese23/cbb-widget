import AppKit
import CBBCore
import SwiftUI
import WidgetKit

/// (team id, dark appearance) → logo image.
public typealias LogoProvider = (String, Bool) -> NSImage?

struct TeamLogo: View {
    let team: Team
    let size: CGFloat
    let logo: LogoProvider
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if let image = logo(team.id, scheme == .dark) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .widgetAccentedRenderingMode(.fullColor)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Text(team.abbreviation.prefix(4))
                .font(.system(size: size * 0.32, weight: .bold))
                .minimumScaleFactor(0.5)
                .frame(width: size, height: size)
                .background(Circle().fill(.quaternary))
        }
    }
}

/// Two stacked team lines (away over home) with the status on the right, Apple Sports style.
struct GameRow: View {
    let game: Game
    let now: Date
    let logo: LogoProvider

    var body: some View {
        MaybeLink(url: game.link) {
            HStack(alignment: .center, spacing: 10) {
            VStack(spacing: 1) {
                teamLine(game.away)
                teamLine(game.home)
            }
            status.frame(width: 84, alignment: .trailing)
            }
            .padding(.vertical, 3)
        }
    }

    private func teamLine(_ c: Competitor) -> some View {
        let dim = game.loser == c
        return HStack(spacing: 5) {
            TeamLogo(team: c.team, size: 18, logo: logo)
            Text(c.rank.map(String.init) ?? "")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(dim ? .tertiary : .secondary)
                .frame(width: 15, alignment: .trailing)
            Text(c.team.abbreviation)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(dim ? .secondary : .primary)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(c.score.map(String.init) ?? "")
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(dim ? .secondary : .primary)
        }
        .frame(height: 17)
    }

    @ViewBuilder private var status: some View {
        VStack(alignment: .trailing, spacing: 1) {
            switch game.state {
            case .live:
                Text(game.statusText).foregroundStyle(.red).fontWeight(.semibold)
            case .final:
                Text(Fmt.final(game.start, now: now)).foregroundStyle(.secondary)
            case .pre, .postponed:
                Text(Fmt.tip(game.start, now: now)).foregroundStyle(.secondary)
            }
            if let caption = BigGames.caption(game) ?? (BigGames.isUpsetInProgress(game) ? .upset : nil) {
                Text(caption.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(caption == .upset ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
            }
        }
        .font(.system(size: 11))
        .lineLimit(1)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let trailing { Text(trailing) }
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.top, 8)
        .padding(.bottom, 1)
    }
}

/// Games separated by hairlines.
struct GameList: View {
    let games: [Game]
    let now: Date
    let logo: LogoProvider

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(games.enumerated()), id: \.element.id) { i, game in
                if i > 0 { Divider().opacity(0.6) }
                GameRow(game: game, now: now, logo: logo)
            }
        }
    }
}

extension EnvironmentValues {
    /// Off when rendering to an image: `ImageRenderer` can't draw `Link`.
    @Entry public var cbbLinksEnabled = true
}

/// Wraps content in a `Link` when there's a URL and links are enabled.
struct MaybeLink<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: () -> Content
    @Environment(\.cbbLinksEnabled) private var enabled

    var body: some View {
        if enabled, let url {
            Link(destination: url, label: content)
        } else {
            content()
        }
    }
}
