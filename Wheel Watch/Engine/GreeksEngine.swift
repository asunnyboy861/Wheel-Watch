import Foundation

struct GreeksResult {
    let delta: Double
    let thetaPerDay: Double
    let gamma: Double
    let vega: Double
    let price: Double
    let iv: Double
    let ivEstimated: Bool
}

enum GreeksEngine {

    static func normCDF(_ x: Double) -> Double {
        let t = 1.0 / (1.0 + 0.2316419 * abs(x))
        let poly = t * (0.319381530 + t * (-0.356563782 + t * (1.781477937
                 + t * (-1.821255978 + t * 1.330274429))))
        let cdf = 1.0 - exp(-x * x / 2.0) / sqrt(2.0 * .pi) * poly
        return x >= 0 ? cdf : 1.0 - cdf
    }

    static func normPDF(_ x: Double) -> Double {
        exp(-x * x / 2.0) / sqrt(2.0 * .pi)
    }

    static func delta(S: Double, K: Double, T: Double,
                      r: Double = 0.04, sigma: Double, isCall: Bool) -> Double {
        guard T > 0, sigma > 0, S > 0, K > 0 else { return intrinsicDelta(S: S, K: K, isCall: isCall) }
        let d1 = (log(S / K) + (r + sigma * sigma / 2) * T) / (sigma * sqrt(T))
        let nd1 = normCDF(d1)
        return isCall ? nd1 : nd1 - 1.0
    }

    static func thetaPerDay(S: Double, K: Double, T: Double,
                            r: Double = 0.04, sigma: Double, isCall: Bool) -> Double {
        guard T > 0, sigma > 0 else { return 0 }
        let d1 = (log(S / K) + (r + sigma * sigma / 2) * T) / (sigma * sqrt(T))
        let d2 = d1 - sigma * sqrt(T)
        var theta = -S * normPDF(d1) * sigma / (2 * sqrt(T))
        theta += isCall ? -r * K * exp(-r * T) * normCDF(d2)
                        :  r * K * exp(-r * T) * normCDF(-d2)
        return -theta / 365.0
    }

    static func gamma(S: Double, K: Double, T: Double,
                      r: Double = 0.04, sigma: Double) -> Double {
        guard T > 0, sigma > 0, S > 0, K > 0 else { return 0 }
        let d1 = (log(S / K) + (r + sigma * sigma / 2) * T) / (sigma * sqrt(T))
        return normPDF(d1) / (S * sigma * sqrt(T))
    }

    static func vega(S: Double, K: Double, T: Double,
                     r: Double = 0.04, sigma: Double) -> Double {
        guard T > 0, sigma > 0, S > 0, K > 0 else { return 0 }
        let d1 = (log(S / K) + (r + sigma * sigma / 2) * T) / (sigma * sqrt(T))
        return S * normPDF(d1) * sqrt(T) / 100.0
    }

    static func bsmPrice(S: Double, K: Double, T: Double,
                         r: Double, sigma: Double, isCall: Bool) -> Double {
        guard T > 0, sigma > 0, S > 0, K > 0 else { return intrinsicValue(S: S, K: K, isCall: isCall) }
        let d1 = (log(S / K) + (r + sigma * sigma / 2) * T) / (sigma * sqrt(T))
        let d2 = d1 - sigma * sqrt(T)
        return isCall ? S * normCDF(d1) - K * exp(-r * T) * normCDF(d2)
                      : K * exp(-r * T) * normCDF(-d2) - S * normCDF(-d1)
    }

    static func impliedVol(marketPrice: Double, S: Double, K: Double, T: Double,
                           r: Double = 0.04, isCall: Bool) -> Double? {
        guard marketPrice > 0, T > 0, S > 0, K > 0 else { return nil }
        guard marketPrice >= intrinsicValue(S: S, K: K, isCall: isCall) else { return nil }
        var lo = 0.01, hi = 3.0
        for _ in 0..<40 {
            let mid = (lo + hi) / 2
            let price = bsmPrice(S: S, K: K, T: T, r: r, sigma: mid, isCall: isCall)
            if abs(price - marketPrice) < 0.005 { return mid }
            price > marketPrice ? (hi = mid) : (lo = mid)
        }
        return (lo + hi) / 2
    }

    private static func intrinsicValue(S: Double, K: Double, isCall: Bool) -> Double {
        isCall ? max(0, S - K) : max(0, K - S)
    }

    private static func intrinsicDelta(S: Double, K: Double, isCall: Bool) -> Double {
        if isCall { return S > K ? 1.0 : 0.0 }
        return S < K ? -1.0 : 0.0
    }
}
