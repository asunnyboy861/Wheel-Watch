import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @State private var icloudSync = UserDefaults.standard.bool(forKey: "icloudSyncEnabled")

    var body: some View {
        Form {
            alertStyleSection
            dataSourcesSection
            syncSection
            purchasesSection
            legalSection
            aboutSection
        }
        .navigationTitle("Settings")
        .onAppear { viewModel.loadActiveProfile(context: context) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var alertStyleSection: some View {
        Section {
            ForEach([("Safe", RiskPresets.safe), ("Balanced", RiskPresets.balanced), ("Spicy", RiskPresets.spicy)], id: \.0) { name, rules in
                Button {
                    viewModel.applyPreset(rules, name: name, context: context)
                } label: {
                    HStack {
                        Label(name, systemImage: name == "Safe" ? "shield.fill" : name == "Balanced" ? "scale.3d" : "flame.fill")
                        Spacer()
                        if viewModel.activeProfileName == name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(uiColor: .systemGreen))
                        } else {
                            Text("\(String(format: "%.2f", rules[0].threshold))Δ · \(Int(rules[1].threshold * 100))%% · \(Int(rules[2].threshold))d")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            NavigationLink("Fine-tune rules") {
                RulesEditorView()
            }
        } header: {
            Text("Alert Style")
        } footer: {
            Text("Presets reflect community-standard wheel targets. Fine-tune any threshold under Rules.")
        }
    }

    private var dataSourcesSection: some View {
        Section {
            HStack {
                Text("Primary source")
                Spacer()
                Text("Yahoo Finance").foregroundStyle(.secondary)
            }
            HStack {
                Text("Fallback source")
                Spacer()
                Text(viewModel.isBYO ? "Finnhub (1-min refresh)" : "Finnhub").foregroundStyle(.secondary)
            }
            SecureField("Your Finnhub API key (optional)", text: $viewModel.finnhubKey)
            Button(viewModel.keySaved ? "Saved ✓" : "Save API key") {
                viewModel.saveFinnhubKey()
            }
            .disabled(viewModel.keySaved)
        } header: {
            Text("Market Data")
        } footer: {
            Text("Pro and BYO Data members can add a Finnhub key as a fast backup source. Keys are stored in the Keychain and never leave this device.")
        }
    }

    private var syncSection: some View {
        Section {
            Toggle("iCloud Sync (optional)", isOn: $icloudSync)
                .disabled(!viewModel.isPro)
                .onChange(of: icloudSync) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "icloudSyncEnabled")
                }
            if !viewModel.isPro {
                Text("iCloud sync is part of Pro.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Sync")
        } footer: {
            Text("Takes effect on next launch. The app stores everything locally by default and works fully without iCloud.")
        }
    }

    private var purchasesSection: some View {
        Section("Purchases") {
            if viewModel.isPro {
                Label("Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color(uiColor: .systemGreen))
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "lock.open")
                }
            }
            if viewModel.isLive {
                Label("Wheel Watch Live active", systemImage: "bolt.fill")
                    .foregroundStyle(Color(uiColor: .systemGreen))
            }
            Button("Restore Purchases") {
                Task { await purchaseManager.restorePurchases() }
            }
            Link("Manage subscriptions", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
        }
    }

    private var legalSection: some View {
        Section("Legal & Support") {
            Link(destination: PolicyLinks.support) {
                Label("Support Page", systemImage: "questionmark.circle")
            }
            Link(destination: PolicyLinks.privacy) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: PolicyLinks.terms) {
                Label("Terms of Use", systemImage: "doc.plaintext")
            }
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .center, spacing: 4) {
                Text("Wheel Watch")
                    .font(.headline)
                Text("Never miss a roll. Your wheel, on watch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.appVersion)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }
}

struct RulesEditorView: View {
    @Environment(\.modelContext) private var context
    @State private var rules: [AlertRule] = RiskPresets.balanced

    var body: some View {
        Form {
            ForEach($rules) { $rule in
                Section {
                    Toggle(rule.metric.title, isOn: $rule.isEnabled)
                    if showsThreshold(rule.metric) {
                        HStack {
                            Text(rule.metric.unitHint)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if rule.metric == .profitTarget {
                                Text("\(Int(rule.threshold * 100))%")
                            } else if rule.metric == .deltaThreshold {
                                Text(String(format: "%.2f", rule.threshold))
                            } else {
                                Text("\(Int(rule.threshold))")
                            }
                            Stepper("", value: $rule.threshold, in: thresholdRange(rule.metric), step: thresholdStep(rule.metric))
                                .labelsHidden()
                                .frame(width: 120)
                        }
                        .onChange(of: rule.threshold) { _ in persist() }
                    }
                }
                .onChange(of: rule.isEnabled) { _ in persist() }
            }
        }
        .navigationTitle("Fine-tune rules")
        .onAppear(perform: load)
    }

    private func showsThreshold(_ metric: AlertMetric) -> Bool {
        metric == .deltaThreshold || metric == .profitTarget || metric == .dteUrgent || metric == .exDividendRisk
    }

    private func thresholdRange(_ metric: AlertMetric) -> ClosedRange<Double> {
        switch metric {
        case .deltaThreshold: return 0.05...0.60
        case .profitTarget: return 0.25...0.95
        case .dteUrgent: return 1...30
        case .exDividendRisk: return 1...15
        default: return 0...1
        }
    }

    private func thresholdStep(_ metric: AlertMetric) -> Double {
        metric == .deltaThreshold ? 0.05 : 1
    }

    private func load() {
        let descriptor = FetchDescriptor<RuleProfile>(predicate: #Predicate { $0.isActive })
        if let profile = (try? context.fetch(descriptor))?.first {
            rules = profile.rules
        }
    }

    private func persist() {
        let descriptor = FetchDescriptor<RuleProfile>(predicate: #Predicate { $0.isActive })
        if let profile = (try? context.fetch(descriptor))?.first {
            profile.rules = rules
            try? context.save()
        }
    }
}
