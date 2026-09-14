import Foundation

enum Severity: Int, Codable, Comparable {
    case green = 0
    case yellow = 1
    case red = 2

    static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .green: return "Collecting"
        case .yellow: return "Check It"
        case .red: return "Act Now"
        }
    }
}

struct PositionSnapshot {
    let symbol: String
    let isCall: Bool
    let strike: Double
    let premium: Double
    let quantity: Int
    let price: Double
    let delta: Double
    let thetaPerDay: Double
    let dte: Int
    let currentOptionValue: Double
    let ivEstimated: Bool
    let exDividendDays: Int?
    let earningsCrossesExpiry: Bool
}

struct Evaluation {
    let severity: Severity
    let messages: [String]
}

enum RuleEngine {

    static func evaluate(_ snap: PositionSnapshot, rules: [AlertRule]) -> Evaluation {
        var messages: [String] = []
        var severity = Severity.green
        let absDelta = abs(snap.delta)

        for rule in rules where rule.isEnabled {
            switch rule.metric {
            case .itmBreach where isBreach(snap):
                severity = max(severity, .red)
                messages.append("\(snap.symbol) breached its \(snap.strike) strike — price \(snap.price.formatted(.number.precision(.fractionLength(2))))")

            case .deltaThreshold where absDelta >= rule.threshold:
                let s: Severity = absDelta >= 0.50 ? .red : .yellow
                severity = max(severity, s)
                messages.append(String(format: "%@ delta %.2f is at or past your %.2f threshold", snap.symbol, absDelta, rule.threshold))

            case .profitTarget:
                guard snap.premium > 0 else { break }
                let ratio = snap.currentOptionValue / snap.premium
                if ratio <= 1 - rule.threshold {
                    severity = max(severity, .yellow)
                    messages.append("\(snap.symbol) has captured \(Int((1 - ratio) * 100))%% of premium — profit target reached")
                }

            case .dteUrgent where snap.dte <= Int(rule.threshold):
                severity = max(severity, .yellow)
                messages.append("\(snap.symbol) expires in \(snap.dte) trading days — roll or let it go")

            case .exDividendRisk:
                if let days = snap.exDividendDays, days <= Int(rule.threshold), isDeepITM(snap) {
                    severity = max(severity, days <= 1 ? .red : .yellow)
                    messages.append("\(snap.symbol) goes ex-dividend in \(days) day(s) while deep ITM — early exercise risk")
                }

            case .earningsCross where snap.earningsCrossesExpiry:
                severity = max(severity, .yellow)
                messages.append("\(snap.symbol) reports earnings before this expiry — IV and gap risk")

            default:
                break
            }
        }

        return Evaluation(severity: severity, messages: messages)
    }

    static func isBreach(_ snap: PositionSnapshot) -> Bool {
        snap.isCall ? snap.price > snap.strike : snap.price < snap.strike
    }

    private static func isDeepITM(_ snap: PositionSnapshot) -> Bool {
        let depth = abs(snap.price - snap.strike) / snap.strike
        return depth > 0.03 && isBreach(snap)
    }
}
