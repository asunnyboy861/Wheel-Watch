import Combine
import Foundation
import SwiftData
import SwiftUI
import PhotosUI
import UIKit
import Vision

struct ParsedOCRFields {
    var strike: Double?
    var premium: Double?
    var expiry: Date?
}

@MainActor
final class AddPositionViewModel: ObservableObject {
    @Published var query = ""
    @Published var searchResults: [SymbolResult] = []
    @Published var selectedSymbol: String?
    @Published var type: OptionType = .csp
    @Published var strikeText = ""
    @Published var premiumText = ""
    @Published var expiry = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @Published var quantityText = "1"
    @Published var livePrice: Double?
    @Published var deviationWarning = false
    @Published var isSearching = false
    @Published var photoItem: PhotosPickerItem?
    @Published var ocrMessage: String?

    var isValid: Bool {
        selectedSymbol != nil && Double(strikeText) != nil && Double(premiumText) != nil && quantity > 0
    }

    var quantity: Int { Int(quantityText) ?? 0 }

    func search() async {
        guard query.count >= 1 else { return }
        isSearching = true
        searchResults = await QuoteService.shared.searchSymbols(query)
        isSearching = false
    }

    func select(_ result: SymbolResult) {
        selectedSymbol = result.symbol
        query = result.symbol
        searchResults = []
        Task { await loadLivePrice() }
    }

    func loadLivePrice() async {
        guard let symbol = selectedSymbol else { return }
        if let quote = try? await QuoteService.shared.fetchQuote(symbol: symbol) {
            livePrice = quote.price
            validateStrike()
        }
    }

    func validateStrike() {
        guard let strike = Double(strikeText), let price = livePrice, price > 0 else {
            deviationWarning = false
            return
        }
        deviationWarning = abs(strike - price) / price > 0.30
    }

    func performOCR(data: Data) {
        ocrMessage = nil
        Task {
            let fields = await OCRProcessor.extractFields(from: data)
            if let strike = fields.strike { strikeText = String(format: "%.0f", strike) }
            if let premium = fields.premium { premiumText = String(format: "%.2f", premium) }
            if let expiry = fields.expiry { self.expiry = expiry }
            ocrMessage = fields.strike == nil && fields.premium == nil
                ? "Couldn't read that screenshot — enter the numbers manually."
                : "Fields filled from screenshot — please review and confirm."
            validateStrike()
        }
    }

    func save(context: ModelContext) -> Bool {
        guard isValid, let symbol = selectedSymbol,
              let strike = Double(strikeText),
              let premium = Double(premiumText) else { return false }
        let position = Position(symbol: symbol,
                                type: type,
                                strike: strike,
                                premium: premium,
                                expiry: expiry,
                                quantity: quantity)
        context.insert(position)
        let entry = EventLogEntry(symbol: symbol,
                                  message: "Position created",
                                  severity: "green",
                                  price: livePrice ?? 0,
                                  delta: 0)
        context.insert(entry)
        try? context.save()
        return true
    }
}

enum OCRProcessor {
    static func extractFields(from data: Data) async -> ParsedOCRFields {
        await Task.detached(priority: .userInitiated) {
            var result = ParsedOCRFields()
            guard let image = UIImage(data: data)?.cgImage else { return result }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            var numbers: [Double] = []
            for line in lines {
                let matches = line.matches(of: /\d+(?:\.\d+)?/)
                for m in matches {
                    if let value = Double(m.output) { numbers.append(value) }
                }
                let formats: [(String, DateFormatter)] = [
                    ("MMM d, yyyy", isoFormatter("MMM d, yyyy")),
                    ("MMM d yyyy", isoFormatter("MMM d yyyy")),
                    ("MM/dd/yyyy", isoFormatter("MM/dd/yyyy")),
                    ("M/d/yyyy", isoFormatter("M/d/yyyy"))
                ]
                for (pattern, formatter) in formats {
                    if line.range(of: pattern, options: .regularExpression) != nil,
                       let date = formatter.date(from: line) {
                        result.expiry = date
                    }
                }
            }
            let sorted = numbers.filter { $0 >= 0.5 }
            if sorted.count >= 2 {
                result.strike = sorted.max(by: { abs($0 - (sorted.first ?? 0)) < abs($1 - (sorted.first ?? 0)) })
                result.premium = sorted.first
                let candidates = sorted.filter { $0 > 20 }
                if let strike = candidates.max() { result.strike = strike }
                if let premium = candidates.filter({ $0 != result.strike }).min() { result.premium = premium }
            }
            return result
        }.value
    }

    private static func isoFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }
}
