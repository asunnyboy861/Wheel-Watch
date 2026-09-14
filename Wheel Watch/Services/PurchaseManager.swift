import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro = false
    @Published var isLive = false
    @Published var isBYO = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    static let proID = "com.zzoutuo.wheelwatch.pro.onetime"
    static let liveMonthlyID = "com.zzoutuo.wheelwatch.live.monthly"
    static let liveYearlyID = "com.zzoutuo.wheelwatch.live.yearly"
    static let byoMonthlyID = "com.zzoutuo.wheelwatch.byo.monthly"
    static let byoYearlyID = "com.zzoutuo.wheelwatch.byo.yearly"
    static let allIDs = [proID, liveMonthlyID, liveYearlyID, byoMonthlyID, byoYearlyID]

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        loadError = nil
        do {
            products = try await Product.products(for: Self.allIDs)
            await refreshEntitlements()
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                } else {
                    loadError = "Purchase could not be verified."
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        isPro = await hasEntitlement(Self.proID)
        let liveMonthlyActive = await hasEntitlement(Self.liveMonthlyID)
        let liveYearlyActive = await hasEntitlement(Self.liveYearlyID)
        isLive = liveMonthlyActive || liveYearlyActive
        let byoMonthlyActive = await hasEntitlement(Self.byoMonthlyID)
        let byoYearlyActive = await hasEntitlement(Self.byoYearlyID)
        isBYO = byoMonthlyActive || byoYearlyActive
    }

    private func hasEntitlement(_ id: String) async -> Bool {
        guard let result = await Transaction.currentEntitlement(for: id) else { return false }
        if case .verified(let transaction) = result {
            return transaction.revocationDate == nil
        }
        return false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.refreshEntitlements()
                    }
                }
            }
        }
    }
}
