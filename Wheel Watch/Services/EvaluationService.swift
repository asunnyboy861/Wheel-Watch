import Foundation
import SwiftData

struct EvaluationResult {
    let positionID: UUID
    let symbol: String
    let severity: Severity
    let messages: [String]
    let snapshot: PositionSnapshot
    let quoteTime: Date
    let quoteSource: QuoteSource
}

enum EvaluationService {

    static func evaluateAll(context: ModelContext) async -> [EvaluationResult] {
        let descriptor = FetchDescriptor<Position>(predicate: #Predicate { $0.isOpen })
        guard let positions = try? context.fetch(descriptor), !positions.isEmpty else { return [] }

        let rulesDescriptor = FetchDescriptor<RuleProfile>(predicate: #Predicate { $0.isActive })
        let activeRules = (try? context.fetch(rulesDescriptor))?.first?.rules ?? RiskPresets.balanced

        var results: [EvaluationResult] = []
        var offline = false

        for position in positions {
            let symbol = position.symbol
            do {
                let quote = try await QuoteService.shared.fetchQuote(symbol: symbol)
                let hv = await QuoteService.shared.historicalVolatility(symbol: symbol)
                let sigma = hv ?? 0.35
                let ivEstimated = hv == nil
                let T = MarketCalendar.yearsToExpiry(position.expiry)
                let isCall = position.type.isCall
                let delta = GreeksEngine.delta(S: quote.price, K: position.strike, T: T, sigma: sigma, isCall: isCall)
                let theta = GreeksEngine.thetaPerDay(S: quote.price, K: position.strike, T: T, sigma: sigma, isCall: isCall)
                let optionValue = GreeksEngine.bsmPrice(S: quote.price, K: position.strike, T: T, r: 0.04, sigma: sigma, isCall: isCall)
                let dte = MarketCalendar.tradingDaysUntil(position.expiry)

                let snap = PositionSnapshot(symbol: symbol,
                                            isCall: isCall,
                                            strike: position.strike,
                                            premium: position.premium,
                                            quantity: position.quantity,
                                            price: quote.price,
                                            delta: delta,
                                            thetaPerDay: theta * Double(position.quantity) * 100,
                                            dte: dte,
                                            currentOptionValue: optionValue,
                                            ivEstimated: ivEstimated,
                                            exDividendDays: ExDividendCalendar.daysUntilExDividend(symbol: symbol),
                                            earningsCrossesExpiry: EarningsCalendar.earningsBefore(expiry: position.expiry, symbol: symbol))

                let evaluation = RuleEngine.evaluate(snap, rules: activeRules)
                if evaluation.severity != .green {
                    let entry = EventLogEntry(symbol: symbol,
                                              message: evaluation.messages.joined(separator: " · "),
                                              severity: "\(evaluation.severity.rawValue)",
                                              price: quote.price,
                                              delta: delta)
                    context.insert(entry)
                    NotificationService.shared.notify(symbol: symbol, severity: evaluation.severity, messages: evaluation.messages)
                }
                results.append(EvaluationResult(positionID: position.id,
                                                symbol: symbol,
                                                severity: evaluation.severity,
                                                messages: evaluation.messages,
                                                snapshot: snap,
                                                quoteTime: quote.fetchedAt,
                                                quoteSource: quote.source))
            } catch {
                offline = true
                if let cached = QuoteService.shared.cachedQuote(symbol: symbol) {
                    let hv = await QuoteService.shared.historicalVolatility(symbol: symbol)
                    let sigma = hv ?? 0.35
                    let T = MarketCalendar.yearsToExpiry(position.expiry)
                    let isCall = position.type.isCall
                    let delta = GreeksEngine.delta(S: cached.price, K: position.strike, T: T, sigma: sigma, isCall: isCall)
                    let theta = GreeksEngine.thetaPerDay(S: cached.price, K: position.strike, T: T, sigma: sigma, isCall: isCall)
                    let optionValue = GreeksEngine.bsmPrice(S: cached.price, K: position.strike, T: T, r: 0.04, sigma: sigma, isCall: isCall)
                    let snap = PositionSnapshot(symbol: symbol,
                                                isCall: isCall,
                                                strike: position.strike,
                                                premium: position.premium,
                                                quantity: position.quantity,
                                                price: cached.price,
                                                delta: delta,
                                                thetaPerDay: theta * Double(position.quantity) * 100,
                                                dte: MarketCalendar.tradingDaysUntil(position.expiry),
                                                currentOptionValue: optionValue,
                                                ivEstimated: true,
                                                exDividendDays: ExDividendCalendar.daysUntilExDividend(symbol: symbol),
                                                earningsCrossesExpiry: EarningsCalendar.earningsBefore(expiry: position.expiry, symbol: symbol))
                    results.append(EvaluationResult(positionID: position.id,
                                                    symbol: symbol,
                                                    severity: .green,
                                                    messages: [],
                                                    snapshot: snap,
                                                    quoteTime: cached.fetchedAt,
                                                    quoteSource: .offline))
                }
            }
        }

        try? context.save()

        if offline {
            NotificationService.shared.sendOfflineNotice()
        }

        let thetaToday = results.filter { $0.severity != .red }.compactMap { $0.snapshot.thetaPerDay > 0 ? $0.snapshot.thetaPerDay : nil }.reduce(0, +)
        let widgetItems = results.map { r in
            WidgetPositionSnapshot(symbol: r.symbol,
                                   dte: r.snapshot.dte,
                                   severity: r.severity.rawValue,
                                   thetaPerDay: r.snapshot.thetaPerDay)
        }
        AppGroupSnapshot.save(positions: widgetItems, thetaToday: thetaToday)

        return results.sorted { $0.severity > $1.severity }
    }

    static func maybeSendDailyReport(results: [EvaluationResult], context: ModelContext) {
        guard MarketCalendar.isAfterCloseToday else { return }
        let defaults = UserDefaults.standard
        let key = "lastDailyReport"
        let formatter = DateFormatter()
        formatter.timeZone = MarketCalendar.eastern
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard defaults.string(forKey: key) != today else { return }
        let theta = results.compactMap { $0.snapshot.thetaPerDay > 0 ? $0.snapshot.thetaPerDay : nil }.reduce(0, +)
        NotificationService.shared.sendDailyReport(thetaTotal: theta, positionCount: results.count)
        defaults.set(today, forKey: key)
    }
}

enum ExDividendCalendar {
    static let knownExDividends: [String: Date] = [:]

    static func daysUntilExDividend(symbol: String) -> Int? {
        guard let date = knownExDividends[symbol.uppercased()], date > Date() else { return nil }
        return MarketCalendar.tradingDaysUntil(date)
    }
}

enum EarningsCalendar {
    static let knownEarnings: [String: Date] = [:]

    static func earningsBefore(expiry: Date, symbol: String) -> Bool {
        guard let earnings = knownEarnings[symbol.uppercased()] else { return false }
        return earnings > Date() && earnings < expiry
    }
}
