import SwiftUI
import Combine

final class DailyLimitManager: ObservableObject {
    static let shared = DailyLimitManager()

    @AppStorage("limit_enabled")       var isEnabled: Bool   = true
    @AppStorage("limit_minutes")       var limitMinutes: Int = 30
    @AppStorage("limit_today_seconds") var todaySeconds: Double = 0
    @AppStorage("limit_date")          private var dateString: String = ""

    var todayMinutes: Int    { Int(todaySeconds / 60) }
    var isAtLimit: Bool      { isEnabled && todaySeconds >= Double(limitMinutes * 60) }
    var isNearLimit: Bool    { isEnabled && percentUsed >= 0.85 && !isAtLimit }
    var percentUsed: Double  { min(1.0, todaySeconds / Double(max(1, limitMinutes) * 60)) }
    var remainingMinutes: Int {
        max(0, limitMinutes - todayMinutes)
    }

    /// Call from exercise views on disappear to accumulate time.
    func recordSession(seconds: Double) {
        resetIfNewDay()
        guard seconds > 1 else { return }  // ignore accidental quick taps
        todaySeconds += seconds
        objectWillChange.send()
    }

    private func resetIfNewDay() {
        let today = dayString(Date())
        if dateString != today {
            todaySeconds = 0
            dateString   = today
        }
    }

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
