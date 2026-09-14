import Foundation

struct StatsSummary {
    let openCount: Int
    let closedCount: Int
    let cumulativePremium: Decimal
    let winRate: Double
    let todayTheta: Double
}

enum StatsService {

    static func summarize(positions: [Position], snapshots: [String: PositionSnapshot]) -> StatsSummary {
        let open = positions.filter { $0.isOpen }
        let closed = positions.filter { !$0.isOpen }
        let cumulative = positions.reduce(Decimal(0)) { $0 + $1.totalPremiumCollected }
        let wins = closed.filter { $0.totalPremiumCollected > 0 }.count
        let winRate = closed.isEmpty ? 0 : Double(wins) / Double(closed.count)
        let todayTheta = open.compactMap { snapshots[$0.symbol]?.thetaPerDay }.reduce(0, +)
        return StatsSummary(openCount: open.count,
                            closedCount: closed.count,
                            cumulativePremium: cumulative,
                            winRate: winRate,
                            todayTheta: todayTheta)
    }

    static let badgeThresholds: [Double] = [1000, 5000, 10000]

    static func earnedBadges(cumulativePremium: Decimal) -> [String] {
        let total = Double(truncating: cumulativePremium as NSDecimalNumber)
        return badgeThresholds.filter { total >= $0 }.map { "🛞 $\($0.formatted()) Premium Club" }
    }

    static func nextBadgeTarget(cumulativePremium: Decimal) -> Double? {
        let total = Double(truncating: cumulativePremium as NSDecimalNumber)
        return badgeThresholds.first { total < $0 }
    }
}
