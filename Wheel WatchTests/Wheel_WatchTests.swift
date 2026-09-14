import Testing
@testable import Wheel_Watch

struct GreeksEngineTests {

    @Test func callDeltaMatchesTextbookValue() {
        let delta = GreeksEngine.delta(S: 100, K: 100, T: 1.0, r: 0.05, sigma: 0.2, isCall: true)
        #expect(abs(delta - 0.636) < 0.02)
    }

    @Test func putDeltaIsNegative() {
        let delta = GreeksEngine.delta(S: 100, K: 100, T: 1.0, r: 0.05, sigma: 0.2, isCall: false)
        #expect(abs(delta + 0.364) < 0.02)
    }

    @Test func callPriceMatchesTextbookValue() {
        let price = GreeksEngine.bsmPrice(S: 100, K: 100, T: 1.0, r: 0.05, sigma: 0.2, isCall: true)
        #expect(abs(price - 10.45) < 0.1)
    }

    @Test func impliedVolRoundTrips() {
        let trueSigma = 0.45
        let price = GreeksEngine.bsmPrice(S: 120, K: 115, T: 0.25, r: 0.04, sigma: trueSigma, isCall: false)
        let iv = GreeksEngine.impliedVol(marketPrice: price, S: 120, K: 115, T: 0.25, r: 0.04, isCall: false)
        #expect(iv != nil)
        #expect(abs(iv! - trueSigma) < 0.01)
    }

    @Test func thetaIsPositiveForSeller() {
        let theta = GreeksEngine.thetaPerDay(S: 100, K: 95, T: 0.1, r: 0.04, sigma: 0.3, isCall: false)
        #expect(theta > 0)
    }

    @Test func gammaAndVegaArePositive() {
        let gamma = GreeksEngine.gamma(S: 100, K: 100, T: 0.5, sigma: 0.25)
        let vega = GreeksEngine.vega(S: 100, K: 100, T: 0.5, sigma: 0.25)
        #expect(gamma > 0)
        #expect(vega > 0)
    }
}

struct RuleEngineTests {

    private func snapshot(price: Double, delta: Double, dte: Int = 30, premium: Double = 2.0, optionValue: Double? = nil, isCall: Bool = false) -> PositionSnapshot {
        PositionSnapshot(symbol: "AAPL",
                         isCall: isCall,
                         strike: 100,
                         premium: premium,
                         quantity: 1,
                         price: price,
                         delta: delta,
                         thetaPerDay: 1.0,
                         dte: dte,
                         currentOptionValue: optionValue ?? premium,
                         ivEstimated: false,
                         exDividendDays: nil,
                         earningsCrossesExpiry: false)
    }

    @Test func greenWhenNothingTriggers() {
        let result = RuleEngine.evaluate(snapshot(price: 110, delta: -0.10), rules: RiskPresets.balanced)
        #expect(result.severity == .green)
        #expect(result.messages.isEmpty)
    }

    @Test func redOnITMBreach() {
        let result = RuleEngine.evaluate(snapshot(price: 95, delta: -0.45), rules: RiskPresets.balanced)
        #expect(result.severity == .red)
        #expect(result.messages.contains { $0.contains("breached") })
    }

    @Test func yellowAtDeltaThreshold() {
        let result = RuleEngine.evaluate(snapshot(price: 104, delta: -0.31), rules: RiskPresets.balanced)
        #expect(result.severity == .yellow)
        #expect(result.messages.first?.contains("delta") == true)
    }

    @Test func redAtHalfDelta() {
        let result = RuleEngine.evaluate(snapshot(price: 94, delta: -0.55), rules: RiskPresets.balanced)
        #expect(result.severity == .red)
    }

    @Test func profitTargetTriggers() {
        let result = RuleEngine.evaluate(snapshot(price: 110, delta: -0.10, premium: 2.0, optionValue: 0.6), rules: RiskPresets.balanced)
        #expect(result.severity == .yellow)
        #expect(result.messages.first?.contains("profit target") == true)
    }

    @Test func dteUrgentTriggers() {
        let result = RuleEngine.evaluate(snapshot(price: 110, delta: -0.10, dte: 5), rules: RiskPresets.balanced)
        #expect(result.severity == .yellow)
        #expect(result.messages.first?.contains("expires") == true)
    }

    @Test func earningsCrossTriggers() {
        var snap = snapshot(price: 110, delta: -0.10)
        snap = PositionSnapshot(symbol: snap.symbol, isCall: snap.isCall, strike: snap.strike, premium: snap.premium,
                                quantity: snap.quantity, price: snap.price, delta: snap.delta, thetaPerDay: snap.thetaPerDay,
                                dte: snap.dte, currentOptionValue: snap.currentOptionValue, ivEstimated: snap.ivEstimated,
                                exDividendDays: nil, earningsCrossesExpiry: true)
        let result = RuleEngine.evaluate(snap, rules: RiskPresets.balanced)
        #expect(result.severity == .yellow)
    }

    @Test func coveredCallBreachIsAboveStrike() {
        let result = RuleEngine.evaluate(snapshot(price: 105, delta: 0.4, isCall: true), rules: RiskPresets.balanced)
        #expect(result.severity == .red)
    }
}
