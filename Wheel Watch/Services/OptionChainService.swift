import Foundation

struct OptionContract: Identifiable, Hashable {
    var id: String { "\(strike)-\(expiry.timeIntervalSince1970)" }
    let strike: Double
    let expiry: Date
    let bid: Double
    let ask: Double
    let isCall: Bool

    var mid: Double {
        bid > 0 && ask > 0 ? (bid + ask) / 2 : max(bid, ask)
    }

    var hasLiquidQuote: Bool { bid > 0 && ask > 0 }
}

struct ChainSnapshot {
    let symbol: String
    let contracts: [OptionContract]
    let fetchedAt: Date
}

enum ChainError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Option chain unavailable right now. Roll Radar will retry — everything else keeps working."
    }
}

final class OptionChainService {
    static let shared = OptionChainService()
    private let session: URLSession

    init() {
        var config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        self.session = URLSession(configuration: config)
    }

    func fetchChain(symbol: String) async throws -> ChainSnapshot {
        let key = symbol.uppercased()
        guard let url = URL(string: "https://query2.finance.yahoo.com/v7/finance/options/\(key)") else {
            throw ChainError.unavailable
        }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChainError.unavailable
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let result = ((json?["optionChain"] as? [String: Any])?["result"] as? [[String: Any]])?.first,
              let options = result["options"] as? [[String: Any]] else {
            throw ChainError.unavailable
        }
        var contracts: [OptionContract] = []
        for opt in options {
            let puts = opt["puts"] as? [[String: Any]] ?? []
            let calls = opt["calls"] as? [[String: Any]] ?? []
            for raw in puts {
                if let c = parse(raw, isCall: false) { contracts.append(c) }
            }
            for raw in calls {
                if let c = parse(raw, isCall: true) { contracts.append(c) }
            }
        }
        guard !contracts.isEmpty else { throw ChainError.unavailable }
        return ChainSnapshot(symbol: key, contracts: contracts, fetchedAt: Date())
    }

    private func parse(_ raw: [String: Any], isCall: Bool) -> OptionContract? {
        guard let strike = raw["strike"] as? Double,
              let expMillis = raw["expiration"] as? Double else { return nil }
        let bid = raw["bid"] as? Double ?? 0
        let ask = raw["ask"] as? Double ?? 0
        return OptionContract(strike: strike,
                              expiry: Date(timeIntervalSince1970: expMillis / 1000),
                              bid: bid, ask: ask, isCall: isCall)
    }
}
