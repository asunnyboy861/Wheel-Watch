import SwiftUI
import SwiftData
import PhotosUI

struct AddPositionView: View {
    var onSaved: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = AddPositionViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @State private var confirmedDeviation = false

    var body: some View {
        NavigationStack {
            Form {
                tickerSection
                styleSection
                positionSection
                if viewModel.deviationWarning && !confirmedDeviation {
                    deviationSection
                }
                if let message = viewModel.ocrMessage {
                    Section {
                        Label(message, systemImage: "doc.text.viewfinder")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Position")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(context: context) {
                            Task {
                                await onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || (viewModel.deviationWarning && !confirmedDeviation))
                }
            }
            .task { await viewModel.loadLivePrice() }
            .onChange(of: viewModel.strikeText) { _ in viewModel.validateStrike() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var tickerSection: some View {
        Section("Ticker") {
            TextField("Search e.g. AAPL", text: $viewModel.query)
                .task(id: viewModel.query) { await viewModel.search() }
            if viewModel.isSearching {
                ProgressView()
            }
            ForEach(viewModel.searchResults.prefix(5)) { result in
                Button {
                    viewModel.select(result)
                } label: {
                    HStack {
                        Text(result.symbol).fontWeight(.semibold)
                        Spacer()
                        Text(result.name).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if let symbol = viewModel.selectedSymbol {
                HStack {
                    Text("Selected").foregroundStyle(.secondary)
                    Spacer()
                    Text(symbol).fontWeight(.bold)
                    if let price = viewModel.livePrice {
                        Text(price.formatted(.number.precision(.fractionLength(2))))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var styleSection: some View {
        Section("Position Type") {
            Picker("Type", selection: $viewModel.type) {
                ForEach(OptionType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var positionSection: some View {
        Section("Contract") {
            HStack {
                Text("Strike")
                Spacer()
                TextField("225", text: $viewModel.strikeText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
            HStack {
                Text("Premium / share")
                Spacer()
                TextField("1.20", text: $viewModel.premiumText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
            DatePicker("Expiry", selection: $viewModel.expiry, displayedComponents: .date)
            HStack {
                Text("Contracts")
                Spacer()
                TextField("1", text: $viewModel.quantityText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
                Label("Import from broker screenshot", systemImage: "doc.text.viewfinder")
            }
            .onChange(of: viewModel.photoItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        viewModel.performOCR(data: data)
                    }
                }
            }
        }
    }

    private var deviationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("That strike is far from the current market price.", systemImage: "exclamationmark.triangle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .systemOrange))
                Text("Please double-check the strike you entered.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Yes — it's correct, keep it") {
                    confirmedDeviation = true
                }
                .font(.footnote.weight(.semibold))
            }
        }
    }
}
