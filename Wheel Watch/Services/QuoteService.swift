import Foundation

struct StockQuote: Codable, Equatable {
    let symbol: String
    let price: Double
    let fetchedAt: Date
    let source: QuoteSource
}

enum QuoteSource: String, Codable {
    case yahoo, finnhub, offline
}

enum QuoteError: LocalizedError {
    case allSourcesDown
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .allSourcesDown: return "Data sources offline — showing last known values."
        case .invalidResponse: return "Unexpected response from market data."
        }
    }
}

struct SymbolResult: Identifiable, Hashable {
    let symbol: String
    let name: String
    var id: String { symbol }
}

final class QuoteService {
    static let shared = QuoteService()
    private let session: URLSession
    private var cache: [String: StockQuote] = [:]

    init(session: URLSession = .shared) {
        var config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    var cachedQuotes: [String: StockQuote] { cache }

    func fetchQuote(symbol: String) async throws -> StockQuote {
        let key = symbol.uppercased()
        if let q = try? await yahooQuote(key) {
            cache[key] = q
            return q
        }
        if let q = try? await finnhubQuote(key) {
            cache[key] = q
            return q
        }
        throw QuoteError.allSourcesDown
    }

    func cachedQuote(symbol: String) -> StockQuote? {
        cache[symbol.uppercased()]
    }

    func historicalVolatility(symbol: String) async -> Double? {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol.uppercased())?range=1y&interval=1d") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await session.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = ((json["chart"] as? [String: Any])?["result"] as? [[String: Any]])?.first,
              let indicators = result["indicators"] as? [String: Any],
              let quotes = (indicators["quote"] as? [[String: Any]])?.first,
              let closes = quotes["close"] as? [Double?] else { return nil }
        let clean = closes.compactMap { $0 }
        guard clean.count > 35 else { return nil }
        let window = Array(clean.suffix(31))
        var returns: [Double] = []
        for i in 1..<window.count where window[i - 1] > 0 {
            returns.append(log(window[i] / window[i - 1]))
        }
        guard returns.count > 5 else { return nil }
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(returns.count - 1)
        return sqrt(variance) * sqrt(252.0)
    }

    func searchSymbols(_ query: String) async -> [SymbolResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=\(encoded)&quotesCount=8&newsCount=0") else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await session.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let quotes = json["quotes"] as? [[String: Any]] else { return [] }
        return quotes.compactMap { q in
            guard let symbol = q["symbol"] as? String,
                  q["quoteType"] as? String == "EQUITY" || q["quoteType"] as? String == "ETF" else { return nil }
            return SymbolResult(symbol: symbol, name: q["shortname"] as? String ?? q["longname"] as? String ?? "")
        }
    }

    private func yahooQuote(_ symbol: String) async throws -> StockQuote {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=1d&interval=1m") else {
            throw QuoteError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let result = ((json?["chart"] as? [String: Any])?["result"] as? [[String: Any]])?.first,
              let meta = result["meta"] as? [String: Any],
              let price = meta["regularMarketPrice"] as? Double else {
            throw QuoteError.invalidResponse
        }
        return StockQuote(symbol: symbol, price: price, fetchedAt: Date(), source: .yahoo)
    }

    private func finnhubQuote(_ symbol: String) async throws -> StockQuote {
        guard let key = KeychainHelper.readString(service: KeychainKeys.service, account: KeychainKeys.finnhubKey), !key.isEmpty else {
            throw QuoteError.allSourcesDown
        }
        guard let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(key)") else {
            throw QuoteError.invalidResponse
        }
        let (data, _) = try await session.data(from: url)
        struct FinnhubQuote: Decodable { let c: Double }
        let json = try JSONDecoder().decode(FinnhubQuote.self, from: data)
        guard json.c > 0 else { throw QuoteError.invalidResponse }
        return StockQuote(symbol: symbol, price: json.c, fetchedAt: Date(), source: .finnhub)
    }
}
