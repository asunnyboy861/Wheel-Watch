import SwiftUI
import SwiftData

struct StatsView: View {
    let snapshots: [String: PositionSnapshot]
    @Environment(\.modelContext) private var context
    @State private var summary: StatsSummary?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let summary {
                    premiumCard(summary)
                    metricsRow(summary)
                    badgesSection(summary)
                } else {
                    ProgressView()
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Stats")
        .onAppear { computeStats() }
        .refreshable { computeStats() }
    }

    private func computeStats() {
        let descriptor = FetchDescriptor<Position>()
        let positions = (try? context.fetch(descriptor)) ?? []
        summary = StatsService.summarize(positions: positions, snapshots: snapshots)
    }

    private func premiumCard(_ summary: StatsSummary) -> some View {
        VStack(spacing: 6) {
            Text("Cumulative premium collected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("$\(summary.cumulativePremium.formatted(.number.precision(.fractionLength(2))))")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color(uiColor: .systemGreen))
            ShareLink(item: shareText(summary), subject: Text("Wheel Watch")) {
                Label("Share battle card", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func shareText(_ summary: StatsSummary) -> String {
        let total = summary.cumulativePremium.formatted(.number.precision(.fractionLength(0)))
        return """
        🛞 Wheel Watch battle card
        Cumulative premium: $\(total)
        Win rate: \(Int(summary.winRate * 100))%
        Open positions: \(summary.openCount)
        Powered by Wheel Watch — Never miss a roll.
        """
    }

    private func metricsRow(_ summary: StatsSummary) -> some View {
        HStack(spacing: 12) {
            metricTile(value: "\(summary.openCount)", label: "Open")
            metricTile(value: "\(summary.closedCount)", label: "Closed")
            metricTile(value: "\(Int(summary.winRate * 100))%", label: "Win rate")
            metricTile(value: String(format: "$%.2f", summary.todayTheta), label: "Theta today")
        }
    }

    private func metricTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func badgesSection(_ summary: StatsSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wheel milestones")
                .font(.headline)
            ForEach(StatsService.badgeThresholds, id: \.self) { threshold in
                HStack {
                    Image(systemName: summary.cumulativePremium >= Decimal(threshold) ? "seal.fill" : "seal")
                        .foregroundStyle(summary.cumulativePremium >= Decimal(threshold) ? Color(uiColor: .systemGreen) : Color.secondary)
                    Text("$\(threshold.formatted()) Premium Club")
                    Spacer()
                    if let next = StatsService.nextBadgeTarget(cumulativePremium: summary.cumulativePremium), next == threshold {
                        Text("next up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if summary.cumulativePremium >= Decimal(threshold) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color(uiColor: .systemGreen))
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
