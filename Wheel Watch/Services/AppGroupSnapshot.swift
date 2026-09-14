import Foundation

struct WidgetPositionSnapshot: Codable {
    let symbol: String
    let dte: Int
    let severity: Int
    let thetaPerDay: Double
}

struct WidgetSnapshot: Codable {
    let positions: [WidgetPositionSnapshot]
    let thetaToday: Double
    let generatedAt: Date
}

enum AppGroupSnapshot {
    static let suiteName = "group.com.zzoutuo.wheelwatch"
    static let snapshotKey = "widget_snapshot"

    static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    static func save(positions: [WidgetPositionSnapshot], thetaToday: Double) {
        guard let defaults = defaults else { return }
        let snap = WidgetSnapshot(positions: positions, thetaToday: thetaToday, generatedAt: Date())
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: snapshotKey)
        }
    }

    static func load() -> WidgetSnapshot? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
