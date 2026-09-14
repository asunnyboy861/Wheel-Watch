import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var rollTarget: Position?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.cards.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    cardList
                }
            }
            .navigationTitle("Wheel Watch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StatsView(snapshots: viewModel.cards.reduce(into: [:]) { $0[$1.position.symbol] = $1.snapshot })
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                    .accessibilityLabel("Stats")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !purchaseManager.isPro && openCount() >= 3 {
                            showPaywall = true
                        } else {
                            showAdd = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add position")
                }
            }
            .refreshable { await viewModel.refresh(context: context) }
            .task {
                NotificationService.requestAuthorization()
                NotificationService.shared.registerCategories()
                BackgroundRefreshService.shared.schedule()
                await viewModel.refresh(context: context)
            }
            .sheet(isPresented: $showAdd) {
                AddPositionView { await viewModel.refresh(context: context) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $rollTarget) { position in
                MarkRollSheet(position: position) { strike, premium, expiry in
                    viewModel.applyRoll(position, newStrike: strike, newPremium: premium, newExpiry: expiry, context: context)
                    Task { await viewModel.refresh(context: context) }
                }
            }
        }
    }

    private func openCount() -> Int {
        viewModel.cards.filter { $0.position.isOpen }.count
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "circle.hexagongrid.circle")
                .font(.system(size: 56))
                .foregroundStyle(Color(uiColor: .systemGreen))
            Text("Add your first CSP — 30 seconds.")
                .font(.title3.weight(.semibold))
            Text("Search a ticker, pick a style, enter 4 numbers. Wheel Watch watches the rest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAdd = true
            } label: {
                Label("Add Position", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardList: some View {
        List {
            Section {
                if viewModel.isOffline {
                    offlineBanner
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                ForEach(viewModel.cards) { card in
                    NavigationLink {
                        PositionDetailView(position: card.position)
                    } label: {
                        PositionCardView(card: card)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.closePosition(card.position, context: context)
                            Task { await viewModel.refresh(context: context) }
                        } label: {
                            Label("Close", systemImage: "xmark.circle")
                        }
                        Button {
                            rollTarget = card.position
                        } label: {
                            Label("Rolled", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .tint(Color(uiColor: .systemGreen))
                    }
                }
                Text("Informational only — not investment advice.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
    }

    private var offlineBanner: some View {
        Label("Data sources offline — showing last known values", systemImage: "wifi.slash")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color(uiColor: .systemOrange))
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color(uiColor: .systemOrange).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct MarkRollSheet: View {
    let position: Position
    let onRoll: (Double, Double, Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var strikeText = ""
    @State private var premiumText = ""
    @State private var expiry = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Rolled to") {
                    TextField("New strike", text: $strikeText)
                        .keyboardType(.decimalPad)
                    TextField("New premium per share", text: $premiumText)
                        .keyboardType(.decimalPad)
                    DatePicker("New expiry", selection: $expiry, displayedComponents: .date)
                }
                Section {
                    Button("Mark Rolled") {
                        if let strike = Double(strikeText), let premium = Double(premiumText) {
                            onRoll(strike, premium, expiry)
                            dismiss()
                        }
                    }
                    .disabled(Double(strikeText) == nil || Double(premiumText) == nil)
                } footer: {
                    Text("Cost basis and premium ledger update automatically.")
                }
            }
            .navigationTitle("Mark Rolled")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                strikeText = String(format: "%.0f", position.strike)
                premiumText = String(format: "%.2f", position.premium)
                expiry = position.expiry
            }
        }
        .presentationDetents([.medium])
    }
}
