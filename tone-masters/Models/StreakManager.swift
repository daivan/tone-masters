import SwiftUI
import Combine

final class StreakManager: ObservableObject {
    @AppStorage("streak_current") var currentStreak: Int = 0
    @AppStorage("streak_longest") var longestStreak: Int = 0
    @AppStorage("streak_lastDate") private var lastDateString: String = ""

    // Call this whenever the user does any practice (e.g., on home screen appear)
    func recordPractice() {
        let today = dayString(Date())
        guard lastDateString != today else { return }  // already counted today

        let yesterday = dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if lastDateString == yesterday {
            currentStreak += 1
        } else {
            currentStreak = 1   // gap in days — reset
        }
        longestStreak = max(longestStreak, currentStreak)
        lastDateString = today
    }

    var isStreakAlive: Bool {
        let today     = dayString(Date())
        let yesterday = dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        return lastDateString == today || lastDateString == yesterday
    }

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
