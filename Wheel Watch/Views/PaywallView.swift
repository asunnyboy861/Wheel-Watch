import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var purchasingID: String?

    private var proProduct: Product? { purchaseManager.products.first { $0.id == PurchaseManager.proID } }
    private var liveMonthly: Product? { purchaseManager.products.first { $0.id == PurchaseManager.liveMonthlyID } }
    private var liveYearly: Product? { purchaseManager.products.first { $0.id == PurchaseManager.liveYearlyID } }
    private var byoMonthly: Product? { purchaseManager.products.first { $0.id == PurchaseManager.byoMonthlyID } }
    private var byoYearly: Product? { purchaseManager.products.first { $0.id == PurchaseManager.byoYearlyID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "circle.hexagongrid.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(uiColor: .systemGreen))
                    Text("Wheel Watch Pro")
                        .font(.title.bold())
                    Text("Your wheel, on watch — with every answer in hand.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if purchaseManager.isPro {
                        unlockedBanner
                    } else if let pro = proProduct {
                        productButton(pro, highlight: true) {
                            featureRow("Unlimited positions", icon: "infinity")
                            featureRow("Roll Radar — know where to roll", icon: "arrow.triangle.2.circlepath")
                            featureRow("Lock-screen widgets + Dynamic Island", icon: "widget.small")
                            featureRow("iCloud sync across devices", icon: "icloud")
                            featureRow("Dual quote sources + milestone badges", icon: "seal.fill")
                        }
                        Text("One-time purchase. Yours forever.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !purchaseManager.isLive {
                        subscriptionSection(title: "Wheel Watch Live",
                                            subtitle: "Server-grade per-minute evaluation + APNs push within 60 seconds + email backup. 7-day free trial.",
                                            monthly: liveMonthly, yearly: liveYearly)
                    }

                    if !purchaseManager.isBYO {
                        subscriptionSection(title: "BYO Data",
                                            subtitle: "Use your own Finnhub/Polygon key for 1-minute refresh — data costs stay yours, savings stay yours.",
                                            monthly: byoMonthly, yearly: byoYearly)
                    }

                    if let error = purchaseManager.loadError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .systemRed))
                    }

                    Button("Restore Purchases") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .font(.footnote)

                    autoRenewalDisclosure

                    HStack(spacing: 20) {
                        Link("Privacy Policy", destination: PolicyLinks.privacy)
                        Link("Terms of Use", destination: PolicyLinks.terms)
                    }
                    .font(.caption2)
                    .padding(.top, 2)

                    Button("Continue with Free — 3 positions") { dismiss() }
                        .font(.footnote)
                        .padding(.bottom, 8)
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchaseManager.loadProducts() }
            .onChange(of: purchaseManager.isPro) { _ in dismiss() }
        }
    }

    private var unlockedBanner: some View {
        Label("Pro is unlocked — thank you!", systemImage: "checkmark.seal.fill")
            .font(.headline)
            .foregroundStyle(Color(uiColor: .systemGreen))
            .padding()
    }

    private func subscriptionSection(title: String, subtitle: String, monthly: Product?, yearly: Product?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            if let yearly, let monthly {
                productButton(yearly, highlight: false) { EmptyView() }
                productButton(monthly, highlight: false) { EmptyView() }
                Text("\(monthly.displayPrice)/month equivalent — annual is pre-selected for the best value.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func productButton(_ product: Product, highlight: Bool, @ViewBuilder features: () -> some View) -> some View {
        Button {
            purchasingID = product.id
            Task {
                await purchaseManager.purchase(product)
                purchasingID = nil
            }
        } label: {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayName.isEmpty ? titleFallback(product) : product.displayName)
                            .font(.headline)
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    if purchasingID == product.id {
                        ProgressView()
                    } else {
                        Text(product.displayPrice)
                            .font(.headline)
                    }
                }
                features()
            }
            .padding(14)
            .background(Color(uiColor: .systemGreen).opacity(highlight ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(uiColor: .systemGreen), lineWidth: highlight ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(purchasingID != nil)
        .accessibilityLabel("Purchase \(titleFallback(product)) for \(product.displayPrice)")
    }

    private func titleFallback(_ product: Product) -> String {
        switch product.id {
        case PurchaseManager.proID: return "Pro — One-Time Unlock"
        case PurchaseManager.liveMonthlyID: return "Live Monthly"
        case PurchaseManager.liveYearlyID: return "Live Annual"
        case PurchaseManager.byoMonthlyID: return "BYO Data Monthly"
        case PurchaseManager.byoYearlyID: return "BYO Data Annual"
        default: return product.displayName
        }
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 18)
                .foregroundStyle(Color(uiColor: .systemGreen))
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }

    private var autoRenewalDisclosure: some View {
        Text("Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. You can manage or cancel anytime in your Apple ID settings. Pro is a one-time purchase and never renews.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}
