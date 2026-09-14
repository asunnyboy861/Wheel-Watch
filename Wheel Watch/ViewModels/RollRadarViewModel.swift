import Combine
import Foundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
final class RollRadarViewModel: ObservableObject {
    struct Candidate: Identifiable {
        let id = UUID()
        let strike: Double
        let expiry: Date
        let mid: Double
        let isSameMonth: Bool
        let netCredit: Double
    }

    @Published var candidates: [Candidate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var copied = false

    func load(position: Position, currentValue: Double?) async {
        isLoading = true
        errorMessage = nil
        candidates = []
        do {
            let chain = try await OptionChainService.shared.fetchChain(symbol: position.symbol)
            let sameMonth = chain.contracts.filter { Calendar.current.isDate($0.expiry, inSameDayAs: position.expiry) }
            let nextMonth = chain.contracts.filter { $0.expiry > position.expiry }
            let targetDelta = 0.30
            let groups: [(Bool, [OptionContract])] = [(true, sameMonth), (false, nextMonth)]
            for (isSame, contracts) in groups {
                let puts = contracts.filter { $0.isCall == position.type.isCall }
                let liquid = puts.filter { $0.hasLiquidQuote }
                guard !liquid.isEmpty else { continue }
                guard let reference = liquid.min(by: { abs($0.strike - position.strike) < abs($1.strike - position.strike) }) else { continue }
                let window = liquid.filter { abs($0.strike - reference.strike) <= 10 }
                for c in window.prefix(3) {
                    let net = c.mid - (currentValue ?? position.premium)
                    candidates.append(Candidate(strike: c.strike, expiry: c.expiry, mid: c.mid, isSameMonth: isSame, netCredit: net))
                }
            }
            if candidates.isEmpty {
                errorMessage = "No liquid same/next-month contracts found for \(position.symbol)."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func orderText(for candidate: Candidate, position: Position) -> String {
        let dte = MarketCalendar.tradingDaysUntil(candidate.expiry)
        let action = position.type.isCall ? "CALL" : "PUT"
        return String(format: "SELL %d %@ %@ %@ %dD ~$%.2f", position.quantity, position.symbol, action, candidate.strike.formatted(), dte, candidate.mid)
    }

    func copyOrder(for candidate: Candidate, position: Position) {
        UIPasteboard.general.string = orderText(for: candidate, position: position)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}
