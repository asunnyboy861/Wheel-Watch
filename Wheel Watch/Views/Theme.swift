import SwiftUI

enum PolicyLinks {
    static let baseURL = "https://asunnyboy861.github.io/Wheel-Watch"

    static var support: URL { URL(string: "\(baseURL)/support.html")! }
    static var privacy: URL { URL(string: "\(baseURL)/privacy.html")! }
    static var terms: URL { URL(string: "\(baseURL)/terms.html")! }
}

enum StateColor {
    static func color(for severity: Severity) -> Color {
        switch severity {
        case .green: return Color(uiColor: .systemGreen)
        case .yellow: return Color(uiColor: .systemOrange)
        case .red: return Color(uiColor: .systemRed)
        }
    }
}
