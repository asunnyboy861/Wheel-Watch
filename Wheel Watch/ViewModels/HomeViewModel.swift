import Combine
import Foundation
import SwiftData
import SwiftUI

struct HomeCard: Identifiable {
    let id: UUID
    let position: Position
    let severity: Severity
    let messages: [String]
    let snapshot: PositionSnapshot?
    let quoteTime: Date
    let quoteSource: QuoteSource

    var unrealizedPct: Double {
        guard let s = snapshot, s.premium > 0 else { return 0 }
        return (1 - s.currentOptionValue / s.premium) * 100
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var cards: [HomeCard] = []
    @Published var isLoading = false
    @Published var isOffline = false
    @Published var errorMessage: String?
    @Published var lastRefreshed: Date?

    func refresh(context: ModelContext) async {
        isLoading = true
        let results = await EvaluationService.evaluateAll(context: context)
        isOffline = results.contains { $0.quoteSource == .offline }
        let descriptor = FetchDescriptor<Position>(predicate: #Predicate { $0.isOpen })
        let positions = (try? context.fetch(descriptor)) ?? []
        var byPosition: [UUID: EvaluationResult] = [:]
        for r in results { byPosition[r.positionID] = r }
        cards = positions.map { p in
            let r = byPosition[p.id]
            return HomeCard(id: p.id,
                            position: p,
                            severity: r?.severity ?? .green,
                            messages: r?.messages ?? [],
                            snapshot: r?.snapshot,
                            quoteTime: r?.quoteTime ?? Date.distantPast,
                            quoteSource: r?.quoteSource ?? .offline)
        }.sorted { lhs, rhs in
            if lhs.severity != rhs.severity { return lhs.severity > rhs.severity }
            return lhs.position.expiry < rhs.position.expiry
        }
        EvaluationService.maybeSendDailyReport(results: results, context: context)
        lastRefreshed = Date()
        isLoading = false
    }

    func closePosition(_ position: Position, context: ModelContext) {
        position.isOpen = false
        let entry = EventLogEntry(symbol: position.symbol,
                                  message: "Position closed",
                                  severity: "green",
                                  price: 0,
                                  delta: 0)
        context.insert(entry)
        try? context.save()
    }

    func applyRoll(_ position: Position, newStrike: Double, newPremium: Double, newExpiry: Date, context: ModelContext) {
        let premiumDelta = (newPremium - position.premium) * Double(position.quantity) * 100
        let entry = EventLogEntry(symbol: position.symbol,
                                  message: String(format: "Rolled to %.0f/%@ for $%.2f net credit", newStrike, newExpiry.formatted(.dateTime.month(.abbreviated).day()), premiumDelta),
                                  severity: "green",
                                  price: 0,
                                  delta: 0)
        context.insert(entry)
        position.strike = newStrike
        position.premium = newPremium
        position.expiry = newExpiry
        position.premiumCollected += Decimal(premiumDelta)
        try? context.save()
    }
}
