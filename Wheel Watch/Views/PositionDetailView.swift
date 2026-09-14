import SwiftUI
import SwiftData

struct PositionDetailView: View {
    let position: Position
    @Environment(\.modelContext) private var context
    @State private var showRollRadar = false
    @State private var snapshot: PositionSnapshot?
    @State private var quoteTime: Date = .distantPast

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let snap = snapshot {
                    greeksGrid(snap)
                    if snap.ivEstimated {
                        Label("IV estimated from 30-day historical volatility — live option quotes unavailable.", systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .systemOrange))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ProgressView("Refreshing market data…")
                        .padding(.vertical, 24)
                }
                eventLogSection
                Text("Informational only — not investment advice.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(position.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showRollRadar = true
                } label: {
                    Label("Roll Radar", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showRollRadar) {
            RollRadarView(position: position, currentValue: snapshot?.currentOptionValue)
        }
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        do {
            let quote = try await QuoteService.shared.fetchQuote(symbol: position.symbol)
            let hv = await QuoteService.shared.historicalVolatility(symbol: position.symbol)
            let sigma = hv ?? 0.35
            let T = MarketCalendar.yearsToExpiry(position.expiry)
            snapshot = PositionSnapshot(symbol: position.symbol,
                                        isCall: position.type.isCall,
                                        strike: position.strike,
                                        premium: position.premium,
                                        quantity: position.quantity,
                                        price: quote.price,
                                        delta: GreeksEngine.delta(S: quote.price, K: position.strike, T: T, sigma: sigma, isCall: position.type.isCall),
                                        thetaPerDay: GreeksEngine.thetaPerDay(S: quote.price, K: position.strike, T: T, sigma: sigma, isCall: position.type.isCall) * Double(position.quantity) * 100,
                                        dte: MarketCalendar.tradingDaysUntil(position.expiry),
                                        currentOptionValue: GreeksEngine.bsmPrice(S: quote.price, K: position.strike, T: T, r: 0.04, sigma: sigma, isCall: position.type.isCall),
                                        ivEstimated: hv == nil,
                                        exDividendDays: ExDividendCalendar.daysUntilExDividend(symbol: position.symbol),
                                        earningsCrossesExpiry: EarningsCalendar.earningsBefore(expiry: position.expiry, symbol: position.symbol))
            quoteTime = quote.fetchedAt
        } catch {
            snapshot = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(position.type.rawValue) · \(position.quantity) contract\(position.quantity == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text("$\(position.strike.formatted())")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("strike · \(position.expiry.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Premium $\(position.premium.formatted(.number.precision(.fractionLength(2))))/share · collected so far \(position.totalPremiumCollected.formatted(.number.precision(.fractionLength(2))))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func greeksGrid(_ snap: PositionSnapshot) -> some View {
        let items: [(String, String)] = [
            ("Price", snap.price.formatted(.number.precision(.fractionLength(2)))),
            ("|Delta|", String(format: "%.2f", abs(snap.delta))),
            ("Theta/day", String(format: "$%.2f", snap.thetaPerDay)),
            ("DTE", "\(snap.dte)"),
            ("Option value", String(format: "$%.2f", snap.currentOptionValue)),
            ("Gamma", String(format: "%.4f", GreeksEngine.gamma(S: snap.price, K: position.strike, T: MarketCalendar.yearsToExpiry(position.expiry), sigma: 0.35))),
            ("Vega", String(format: "%.3f", GreeksEngine.vega(S: snap.price, K: position.strike, T: MarketCalendar.yearsToExpiry(position.expiry), sigma: 0.35)))
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 2) {
                    Text(item.1)
                        .font(.system(.headline, design: .rounded))
                    Text(item.0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var eventLogSection: some View {
        let symbol = position.symbol
        let descriptor = FetchDescriptor<EventLogEntry>(predicate: #Predicate { $0.symbol == symbol }, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let logs = (try? context.fetch(descriptor)) ?? []
        return VStack(alignment: .leading, spacing: 8) {
            Text("Why did it alert?")
                .font(.headline)
            if logs.isEmpty {
                Text("No alerts recorded yet for this position.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(logs.prefix(20)) { log in
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.message)
                        .font(.subheadline)
                    Text("\(log.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())) · price \(log.price.formatted()) · delta \(String(format: "%.2f", log.delta))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
