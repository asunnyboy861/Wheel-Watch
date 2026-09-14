import Foundation
import SwiftData

@Model
final class EventLogEntry {
    var id: UUID = UUID()
    var symbol: String = ""
    var message: String = ""
    var severityRaw: String = "green"
    var price: Double = 0
    var delta: Double = 0
    var createdAt: Date = Date()

    init(symbol: String, message: String, severity: String, price: Double, delta: Double) {
        self.id = UUID()
        self.symbol = symbol
        self.message = message
        self.severityRaw = severity
        self.price = price
        self.delta = delta
        self.createdAt = Date()
    }
}
