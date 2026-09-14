import Foundation
import BackgroundTasks
import SwiftData

final class BackgroundRefreshService {
    static let shared = BackgroundRefreshService()
    static let taskIdentifier = "com.zzoutuo.wheelwatch.refresh"

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { [weak self] task in
            self?.handle(task: task)
        }
    }

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(task: BGTask) {
        schedule()
        let work = Task { @MainActor in
            if let context = AppEnvironment.shared.mainContext {
                let results = await EvaluationService.evaluateAll(context: context)
                EvaluationService.maybeSendDailyReport(results: results, context: context)
            }
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
