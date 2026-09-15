import SwiftUI

struct PositionCardView: View {
    let card: HomeCard
    @State private var playedHaptic = false

    private var snap: PositionSnapshot? { card.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                statusBadge
                Spacer()
                if let snap {
                    Text("\(card.position.symbol) \(card.position.strike.formatted()) \(card.position.type.shortName)")
                        .font(.headline)
                    Spacer()
                    Text("\(snap.dte)d")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StateColor.color(for: card.severity))
                }
            }

            if let snap {
                HStack(alignment: .firstTextBaseline) {
                    numberColumn(value: "\(snap.price.formatted(.number.precision(.fractionLength(2))))",
                                 label: "vs strike \(card.position.strike.formatted())")
                    numberColumn(value: String(format: "%.2f", abs(snap.delta)), label: "|delta|")
                    numberColumn(value: String(format: "$%.2f", snap.thetaPerDay), label: "theta/day")
                    numberColumn(value: String(format: "%.0f%%", card.unrealizedPct), label: "premium kept")
                    if snap.ivEstimated {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color(uiColor: .systemOrange))
                            .accessibilityLabel("IV estimated from historical volatility")
                    }
                }
                if !card.messages.isEmpty {
                    Text(card.messages.first ?? "")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } else {
                Text("Waiting for market data…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(quoteIsStale ? Color(uiColor: .systemOrange) : Color(uiColor: .systemGreen))
                    .frame(width: 6, height: 6)
                Text("Quote \(card.quoteSource == .offline ? "cached" : card.quoteSource.rawValue) · \(card.quoteTime.formatted(.relative(presentation: .named))))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Informational only — not investment advice.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(StateColor.color(for: card.severity).opacity(0.55), lineWidth: card.severity == .green ? 0.5 : 1.5)
        )
        .onAppear {
            if card.severity == .red && !playedHaptic {
                playedHaptic = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.position.symbol) \(card.position.type.rawValue), status \(card.severity.title)")
    }

    private var quoteIsStale: Bool {
        Date().timeIntervalSince(card.quoteTime) > 20 * 60
    }

    private var statusBadge: some View {
        Text(card.severity.title)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(StateColor.color(for: card.severity).opacity(0.15), in: Capsule())
            .foregroundStyle(StateColor.color(for: card.severity))
    }

    private func numberColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
