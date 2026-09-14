import SwiftUI
import SwiftData
import BackgroundTasks
import UserNotifications

@main
struct Wheel_WatchApp: App {
    let container: ModelContainer

    init() {
        let resolvedContainer = Self.makeContainer()
        container = resolvedContainer
        Task { @MainActor in
            AppEnvironment.shared.container = resolvedContainer
        }
        BackgroundRefreshService.shared.register()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Position.self, RuleProfile.self, EventLogEntry.self])
        let wantsCloud = UserDefaults.standard.bool(forKey: "icloudSyncEnabled")
            && FileManager.default.ubiquityIdentityToken != nil
        do {
            if wantsCloud {
                let cloudConfig = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.zzoutuo.wheelwatch"))
                return try ModelContainer(for: schema, configurations: [cloudConfig])
            }
            return try ModelContainer(for: schema, configurations: [ModelConfiguration()])
        } catch {
            do {
                return try ModelContainer(for: schema, configurations: [ModelConfiguration()])
            } catch {
                fatalError("Could not create the database: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(container)
        }
    }
}
