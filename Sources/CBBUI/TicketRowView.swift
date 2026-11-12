import CBBCore
import SwiftUI

/// A claim, drawn like a Calendar event: coloured bar, title, details, time on the right.
struct TicketRowView: View {
    let row: TicketRow

    private var barColor: Color {
        switch row.state {
        case .quiet: .secondary.opacity(0.5)
        case .soon: .yellow
        case .open: .green
        }
    }

    var body: some View {
        MaybeLink(url: TicketSchedule.claimURL) {
            HStack(alignment: .center, spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5).fill(barColor).frame(width: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(row.claim.squad.rawValue) vs \(row.claim.opponent)")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(Fmt.arena(row.claim.arena)) · \(Fmt.dayDate(row.claim.gameDay))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                Spacer(minLength: 6)
                trailing
                    .font(.system(size: 11))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 3)
        }
    }

    @ViewBuilder private var trailing: some View {
        VStack(alignment: .trailing, spacing: 1) {
            switch row.state {
            case .quiet:
                Text("Claim opens").foregroundStyle(.secondary)
                Text(Fmt.claim(row.claim.opens)).foregroundStyle(.secondary)
            case .soon:
                Text("Opens in \(Text(row.claim.opens, style: .relative))")
                    .fontWeight(.semibold).foregroundStyle(.yellow)
                Text(Fmt.claim(row.claim.opens)).foregroundStyle(.secondary)
            case .open:
                Text("Claim open").fontWeight(.semibold).foregroundStyle(.green)
                Text("Closes \(Fmt.claim(row.claim.closes))").foregroundStyle(.secondary)
            }
        }
    }
}
