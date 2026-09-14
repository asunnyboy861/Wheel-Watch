import WidgetKit
import SwiftUI

@main
struct WheelWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextExpiryWidget()
        ThetaSummaryWidget()
    }
}

struct WidgetPosition: Identifiable, Codable {
    let symbol: String
    let dte: Int
    let severity: Int
    let thetaPerDay: Double
    var id: String { symbol }
}

struct WidgetData: Codable {
    let positions: [WidgetPosition]
    let thetaToday: Double
    let generatedAt: Date
}

enum WidgetStore {
    static let suiteName = "group.com.zzoutuo.wheelwatch"
    static let key = "widget_snapshot"

    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}

func severityColor(_ raw: Int) -> Color {
    switch raw {
    case 2: return Color(uiColor: .systemRed)
    case 1: return Color(uiColor: .systemOrange)
    default: return Color(uiColor: .systemGreen)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
}

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: .now, data: WidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: .now, data: WidgetStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct NextExpiryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextExpiryWidget", provider: WidgetProvider()) { entry in
            NextExpiryView(entry: entry)
        }
        .configurationDisplayName("Next Expiry")
        .description("Countdown ring for your nearest option expiry.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

struct NextExpiryView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    private var nearest: WidgetPosition? { entry.data?.positions.min { $0.dte < $1.dte } }

    var body: some View {
        switch family {
        case .accessoryCircular:
            if let nearest {
                ZStack {
                    ProgressView(value: 1.0 - Double(min(nearest.dte, 30)) / 30.0)
                        .progressViewStyle(.circular)
                        .tint(severityColor(nearest.severity))
                    Text("\(nearest.dte)d")
                        .font(.headline)
                }
            } else {
                Image(systemName: "circle.hexagongrid.circle")
            }
        case .accessoryRectangular:
            if let nearest {
                VStack(alignment: .leading) {
                    Text("\(nearest.symbol) \(nearest.dte)d")
                        .font(.headline)
                    Text("Nearest expiry")
                        .font(.caption2)
                }
            } else {
                Text("Open Wheel Watch")
                    .font(.caption2)
            }
        default:
            VStack(alignment: .leading, spacing: 4) {
                if let nearest {
                    HStack {
                        Circle().fill(severityColor(nearest.severity)).frame(width: 8, height: 8)
                        Text("\(nearest.symbol) · \(nearest.dte)d")
                            .font(.headline)
                    }
                    Text("Nearest expiry")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Add your first CSP")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Informational only")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(4)
        }
    }
}

struct ThetaSummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ThetaSummaryWidget", provider: WidgetProvider()) { entry in
            ThetaSummaryView(entry: entry)
        }
        .configurationDisplayName("Wheel Summary")
        .description("Top pending positions and today's theta income.")
        .supportedFamilies([.systemMedium])
    }
}

struct ThetaSummaryView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Wheel Watch")
                    .font(.caption.weight(.bold))
                Spacer()
                if let data = entry.data {
                    Text(String(format: "+$%.2f theta", data.thetaToday))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(uiColor: .systemGreen))
                }
            }
            if let data = entry.data, !data.positions.isEmpty {
                ForEach(Array(data.positions.sorted { $0.dte < $1.dte }.prefix(3))) { p in
                    HStack {
                        Circle()
                            .fill(severityColor(p.severity))
                            .frame(width: 7, height: 7)
                        Text(p.symbol)
                            .font(.caption.weight(.medium))
                        Spacer()
                        Text("\(p.dte)d")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Add your first CSP — 30 seconds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text("Informational only — not investment advice.")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .padding(4)
        .widgetURL(URL(string: "wheelwatch://open"))
    }
}
