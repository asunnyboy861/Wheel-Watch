import Foundation
import SwiftData

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()
    var container: ModelContainer?

    var mainContext: ModelContext? { container?.mainContext }
}
