import CBBCore
import SwiftUI

private let uconn = BigGames.uconnID

/// Header, the men's next/live game with the last result, and the women's ranked-opponent line.
struct UConnBlock: View {
    let board: Board
    let logo: LogoProvider

    private var uconnTeam: Team {
        board.allGames.compactMap { $0.competitor(uconn)?.team }.first
            ?? Team(id: uconn, abbreviation: "CONN", location: "UConn")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            menGame.padding(.top, 8)
            if let w = board.women { womenLine(w).padding(.top, 8) }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            TeamLogo(team: uconnTeam, size: 20, logo: logo)
            Text("UConn").font(.system(size: 13, weight: .bold))
            Spacer()
            Text(headerMeta).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private var headerMeta: String {
        [board.uconn.record.map(Fmt.record), board.uconn.rank.map { "AP \($0)" }]
            .compactMap { $0 }.joined(separator: " · ")
    }

    @ViewBuilder private var menGame: some View {
        if let g = board.uconn.live ?? board.uconn.next {
            gameLink(g) {
                HStack(spacing: 10) {
                    matchupLogos(g)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(opponentTitle(g)).font(.system(size: 15, weight: .bold)).lineLimit(1)
                        Text(subtitle(g)).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    if g.state == .live {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(Fmt.result(g, for: uconn) ?? "").font(.system(size: 15, weight: .bold)).monospacedDigit()
                            Text(g.statusText).font(.system(size: 11, weight: .semibold)).foregroundStyle(.red)
                        }
                    } else {
                        lastResult
                    }
                }
            }
        } else {
            HStack {
                Text("No games scheduled").font(.system(size: 13)).foregroundStyle(.secondary)
                Spacer()
                lastResult
            }
        }
    }

    @ViewBuilder private var lastResult: some View {
        if let last = board.uconn.last, let result = Fmt.result(last, for: uconn) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(result).font(.system(size: 12, weight: .semibold)).monospacedDigit()
                Text(last.opponent(of: uconn)?.team.location ?? "")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    private func womenLine(_ g: Game) -> some View {
        gameLink(g) {
            HStack(spacing: 6) {
                Text("Women").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
                if let opp = g.opponent(of: uconn) { TeamLogo(team: opp.team, size: 16, logo: logo) }
                Text("""
                    \(g.competitor(uconn)?.isHome == true ? "vs " : "at ")\
                    \(Text(g.opponent(of: uconn)?.rank.map { "\($0) " } ?? "").foregroundStyle(.secondary))\
                    \(g.opponent(of: uconn)?.team.location ?? "")
                    """)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 6)
                Group {
                    switch g.state {
                    case .live:
                        Text("\(Fmt.result(g, for: uconn) ?? "")  \(Text(g.statusText).foregroundStyle(.red))")
                            .fontWeight(.semibold)
                    case .final:
                        Text(Fmt.result(g, for: uconn) ?? "Final").fontWeight(.semibold)
                    case .pre, .postponed:
                        Text(Fmt.when(g.start, now: board.now)).foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 11))
                .monospacedDigit()
            }
        }
    }

    private func matchupLogos(_ g: Game) -> some View {
        HStack(spacing: 3) {
            TeamLogo(team: uconnTeam, size: 30, logo: logo)
            Text(g.competitor(uconn)?.isHome == true ? "vs" : "at")
                .font(.system(size: 10)).foregroundStyle(.tertiary)
            if let opp = g.opponent(of: uconn) { TeamLogo(team: opp.team, size: 30, logo: logo) }
        }
    }

    private func opponentTitle(_ g: Game) -> String {
        guard let opp = g.opponent(of: uconn) else { return "" }
        return (opp.rank.map { "#\($0) " } ?? "") + opp.team.location
    }

    private func subtitle(_ g: Game) -> String {
        let when = Fmt.when(g.start, now: board.now)
        guard let venue = g.venue else { return when }
        return "\(when) · \(venue.replacingOccurrences(of: "M&T Bank Center at ", with: "").replacingOccurrences(of: "PeoplesBank Arena", with: "PeoplesBank"))"
    }

    @ViewBuilder private func gameLink<Content: View>(_ g: Game, @ViewBuilder _ content: @escaping () -> Content) -> some View {
        MaybeLink(url: g.link, content: content)
    }
}
