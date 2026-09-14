import Foundation
import SwiftData

enum AlertMetric: String, Codable, CaseIterable, Identifiable {
    case deltaThreshold
    case profitTarget
    case dteUrgent
    case itmBreach
    case exDividendRisk
    case earningsCross

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deltaThreshold: return "Delta Threshold"
        case .profitTarget: return "Profit Target"
        case .dteUrgent: return "Days to Expiration"
        case .itmBreach: return "ITM Breach"
        case .exDividendRisk: return "Ex-Dividend Risk"
        case .earningsCross: return "Earnings Crossing"
        }
    }

    var unitHint: String {
        switch self {
        case .deltaThreshold: return "|delta| ≥"
        case .profitTarget: return "keep %"
        case .dteUrgent: return "days"
        case .itmBreach: return "auto"
        case .exDividendRisk: return "days"
        case .earningsCross: return "auto"
        }
    }
}

struct AlertRule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var metric: AlertMetric
    var threshold: Double
    var isEnabled: Bool = true

    enum CodingKeys: String, CodingKey {
        case id, metric, threshold, isEnabled
    }

    init(metric: AlertMetric, threshold: Double, isEnabled: Bool = true) {
        self.id = UUID()
        self.metric = metric
        self.threshold = threshold
        self.isEnabled = isEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        metric = try c.decode(AlertMetric.self, forKey: .metric)
        threshold = try c.decode(Double.self, forKey: .threshold)
        isEnabled = try c.decode(Bool.self, forKey: .isEnabled)
    }
}

enum RiskPresets {
    static let safe: [AlertRule] = [
        AlertRule(metric: .deltaThreshold, threshold: 0.20),
        AlertRule(metric: .profitTarget, threshold: 0.75),
        AlertRule(metric: .dteUrgent, threshold: 7),
        AlertRule(metric: .itmBreach, threshold: 0),
        AlertRule(metric: .exDividendRisk, threshold: 5),
        AlertRule(metric: .earningsCross, threshold: 0)
    ]

    static let balanced: [AlertRule] = [
        AlertRule(metric: .deltaThreshold, threshold: 0.30),
        AlertRule(metric: .profitTarget, threshold: 0.50),
        AlertRule(metric: .dteUrgent, threshold: 7),
        AlertRule(metric: .itmBreach, threshold: 0),
        AlertRule(metric: .exDividendRisk, threshold: 5),
        AlertRule(metric: .earningsCross, threshold: 0)
    ]

    static let spicy: [AlertRule] = [
        AlertRule(metric: .deltaThreshold, threshold: 0.40),
        AlertRule(metric: .profitTarget, threshold: 0.50),
        AlertRule(metric: .dteUrgent, threshold: 5),
        AlertRule(metric: .itmBreach, threshold: 0),
        AlertRule(metric: .exDividendRisk, threshold: 5),
        AlertRule(metric: .earningsCross, threshold: 0)
    ]
}

@Model
final class RuleProfile {
    var id: UUID = UUID()
    var name: String = "Balanced"
    var rulesData: Data = Data()
    var isActive: Bool = false

    var rules: [AlertRule] {
        get {
            (try? JSONDecoder().decode([AlertRule].self, from: rulesData)) ?? RiskPresets.balanced
        }
        set {
            rulesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(name: String, rules: [AlertRule], isActive: Bool) {
        self.id = UUID()
        self.name = name
        self.rules = rules
        self.isActive = isActive
    }
}
