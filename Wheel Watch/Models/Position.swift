import Foundation
import SwiftData

enum OptionType: String, Codable, CaseIterable, Identifiable {
    case csp = "Cash-Secured Put"
    case cc = "Covered Call"

    var id: String { rawValue }
    var isCall: Bool { self == .cc }
    var shortName: String { self == .csp ? "CSP" : "CC" }
}

@Model
final class Position {
    var id: UUID = UUID()
    var symbol: String = ""
    var typeRaw: String = OptionType.csp.rawValue
    var strike: Double = 0
    var premium: Double = 0
    var expiry: Date = Date()
    var quantity: Int = 1
    var adjustedBasis: Double = 0
    var premiumCollected: Decimal = 0
    var isOpen: Bool = true
    var createdAt: Date = Date()

    var type: OptionType {
        get { OptionType(rawValue: typeRaw) ?? .csp }
        set { typeRaw = newValue.rawValue }
    }

    var totalPremiumCollected: Decimal {
        premiumCollected * Decimal(quantity) * 100
    }

    init(symbol: String, type: OptionType, strike: Double, premium: Double, expiry: Date, quantity: Int) {
        self.id = UUID()
        self.symbol = symbol.uppercased()
        self.typeRaw = type.rawValue
        self.strike = strike
        self.premium = premium
        self.expiry = expiry
        self.quantity = max(1, quantity)
        self.adjustedBasis = strike
        self.premiumCollected = 0
        self.isOpen = true
        self.createdAt = Date()
    }
}
