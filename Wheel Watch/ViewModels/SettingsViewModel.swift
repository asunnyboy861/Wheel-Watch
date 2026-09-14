import Foundation
import SwiftData
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isPro = false
    @Published var isLive = false
    @Published var isBYO = false
    @Published var activeProfileName = "Balanced"
    @Published var finnhubKey = ""
    @Published var keySaved = false
    private let purchaseManager = PurchaseManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        purchaseManager.$isPro.assign(to: &$isPro)
        purchaseManager.$isLive.assign(to: &$isLive)
        purchaseManager.$isBYO.assign(to: &$isBYO)
        finnhubKey = KeychainHelper.readString(service: KeychainKeys.service, account: KeychainKeys.finnhubKey) ?? ""
    }

    func applyPreset(_ rules: [AlertRule], name: String, context: ModelContext) {
        let descriptor = FetchDescriptor<RuleProfile>(predicate: #Predicate { $0.isActive })
        for profile in (try? context.fetch(descriptor)) ?? [] {
            profile.isActive = false
        }
        let all = FetchDescriptor<RuleProfile>()
        if let existing = (try? context.fetch(all))?.first(where: { $0.name == name }) {
            existing.rules = rules
            existing.isActive = true
        } else {
            context.insert(RuleProfile(name: name, rules: rules, isActive: true))
        }
        activeProfileName = name
        try? context.save()
    }

    func loadActiveProfile(context: ModelContext) {
        let descriptor = FetchDescriptor<RuleProfile>(predicate: #Predicate { $0.isActive })
        if let profile = (try? context.fetch(descriptor))?.first {
            activeProfileName = profile.name
        } else {
            applyPreset(RiskPresets.balanced, name: "Balanced", context: context)
        }
    }

    func saveFinnhubKey() {
        let trimmed = finnhubKey.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            KeychainHelper.delete(service: KeychainKeys.service, account: KeychainKeys.finnhubKey)
        } else {
            KeychainHelper.saveString(trimmed, service: KeychainKeys.service, account: KeychainKeys.finnhubKey)
        }
        keySaved = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            keySaved = false
        }
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
