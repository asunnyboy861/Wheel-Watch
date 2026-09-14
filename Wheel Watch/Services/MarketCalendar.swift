import Foundation

enum MarketCalendar {
    static let eastern = TimeZone(identifier: "America/New_York")!

    private static var etCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = eastern
        return c
    }

    static var isWeekday: Bool {
        let w = etCalendar.component(.weekday, from: Date())
        return w != 1 && w != 7
    }

    static var isMarketOpen: Bool {
        guard isWeekday else { return false }
        let comps = etCalendar.dateComponents([.hour, .minute], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return minutes >= 570 && minutes < 960
    }

    static var isQuietHours: Bool {
        let comps = etCalendar.dateComponents([.hour, .minute], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return minutes >= 1260 || minutes < 390
    }

    static var isAfterCloseToday: Bool {
        guard isWeekday else { return false }
        let comps = etCalendar.dateComponents([.hour, .minute], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return minutes >= 960
    }

    static func tradingDaysUntil(_ target: Date, from reference: Date = Date()) -> Int {
        let cal = etCalendar
        let start = cal.startOfDay(for: reference)
        let end = cal.startOfDay(for: target)
        guard end > start else { return 0 }
        var count = 0
        var cursor = start
        while cursor < end {
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            let w = cal.component(.weekday, from: cursor)
            if w != 1 && w != 7 { count += 1 }
        }
        return count
    }

    static func yearsToExpiry(_ expiry: Date, from reference: Date = Date()) -> Double {
        let days = tradingDaysUntil(expiry, from: reference)
        return Double(max(days, 0)) / 252.0
    }
}
