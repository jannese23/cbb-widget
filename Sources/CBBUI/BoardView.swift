import AppKit
import CBBCore
import SwiftUI

/// The extra-large widget's content: UConn, tickets and coming-up games on the left; today's and
/// the latest ranked results on the right. No outer padding: the widget's content margins supply it.
public struct BoardView: View {
    /// The extra-large widget's size on macOS, including the system's 16 pt content margins.
    public static let size = CGSize(width: 712, height: 344)

    let board: Board
    let logo: LogoProvider
    let updatedAt: Date?
    let showUpdated: Bool

    public init(board: Board, logo: @escaping LogoProvider, updatedAt: Date?, showUpdated: Bool) {
        self.board = board
        self.logo = logo
        self.updatedAt = updatedAt
        self.showUpdated = showUpdated
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 24) {
            left.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            right.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var left: some View {
        VStack(alignment: .leading, spacing: 0) {
            UConnBlock(board: board, logo: logo)
            if !board.tickets.isEmpty {
                VStack(spacing: 2) {
                    ForEach(board.tickets, id: \.claim) { TicketRowView(row: $0) }
                }
                .padding(.top, 8)
            }
            if !board.comingUp.isEmpty {
                SectionHeader(title: "Coming up")
                GameList(games: board.comingUp, now: board.now, logo: logo)
            }
        }
    }

    private var right: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Today").font(.system(size: 13, weight: .bold))
                Spacer()
                Text(rightMeta).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if board.today.isEmpty {
                Text("No big games today")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                GameList(games: board.today, now: board.now, logo: logo).padding(.top, 2)
            }
            if !board.latest.isEmpty {
                SectionHeader(title: "Latest")
                GameList(games: board.latest, now: board.now, logo: logo)
            }
        }
    }

    private var rightMeta: String {
        if showUpdated, let updatedAt { return "Updated \(Fmt.time(updatedAt))" }
        return Fmt.dayDate(board.now)
    }
}

/// Shown when there's no data at all yet (first run, offline).
public struct PlaceholderView: View {
    let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "basketball")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(message).font(.system(size: 13, weight: .semibold))
            Text("It'll try again in a few minutes.").font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
