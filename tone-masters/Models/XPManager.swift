import SwiftUI
import Combine

// MARK: - Badge

struct Badge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String      // SF Symbol
    let xpReward: Int     // bonus XP awarded on first unlock
}

// MARK: - XPManager

final class XPManager: ObservableObject {
    static let shared = XPManager()

    @AppStorage("xp_total")           var totalXP: Int = 0
    @AppStorage("xp_badge_ids")       private var badgeIDsString: String = ""

    // 100 XP per level
    var level: Int            { totalXP / 100 + 1 }
    var xpInCurrentLevel: Int { totalXP % 100 }
    var xpToNextLevel: Int    { 100 }

    // MARK: - Badge catalogue

    static let allBadges: [Badge] = [
        Badge(id: "first_practice", name: "First Steps",
              description: "Open the app and practice for the first time",
              icon: "star.fill",              xpReward: 0),
        Badge(id: "pitch_trail",    name: "Pitch Perfect",
              description: "Complete a Pitch Trail session",
              icon: "waveform",               xpReward: 25),
        Badge(id: "audiation",      name: "Inner Ear",
              description: "Complete an Audiation drill",
              icon: "ear.fill",               xpReward: 50),
        Badge(id: "siren",          name: "Siren Song",
              description: "Complete a Siren portamento exercise",
              icon: "flame.fill",             xpReward: 25),
        Badge(id: "interval",       name: "Leap of Faith",
              description: "Complete an Interval Training session",
              icon: "arrow.up.right",         xpReward: 50),
        Badge(id: "echo_me",        name: "Echo Chamber",
              description: "Complete an Echo Me drill",
              icon: "person.wave.2.fill",     xpReward: 50),
        Badge(id: "follow_song",    name: "Songwriter",
              description: "Complete a Follow the Song session",
              icon: "music.note",             xpReward: 75),
        Badge(id: "streak_7",       name: "Week Warrior",
              description: "Reach a 7-day practice streak",
              icon: "7.circle.fill",          xpReward: 100),
        Badge(id: "streak_30",      name: "Month Master",
              description: "Reach a 30-day practice streak",
              icon: "calendar.badge.checkmark", xpReward: 500),
        Badge(id: "xp_500",         name: "Rising Voice",
              description: "Earn 500 total XP",
              icon: "bolt.fill",              xpReward: 0),
        Badge(id: "xp_1000",        name: "Powerhouse",
              description: "Earn 1000 total XP",
              icon: "bolt.circle.fill",       xpReward: 0),
    ]

    // MARK: - Unlock state

    var unlockedIDs: Set<String> {
        get { Set(badgeIDsString.split(separator: ",").map(String.init).filter { !$0.isEmpty }) }
        set { badgeIDsString = newValue.sorted().joined(separator: ",") }
    }

    var unlockedBadges: [Badge] {
        Self.allBadges.filter { unlockedIDs.contains($0.id) }
    }

    var lockedBadges: [Badge] {
        Self.allBadges.filter { !unlockedIDs.contains($0.id) }
    }

    // MARK: - Awarding

    /// Award flat XP and optionally unlock a badge by ID.
    func award(xp: Int, badge badgeID: String? = nil) {
        totalXP += xp
        if let badgeID { unlock(badgeID) }

        // Milestone checks
        unlock("first_practice")
        if totalXP >= 500  { unlock("xp_500") }
        if totalXP >= 1000 { unlock("xp_1000") }

        objectWillChange.send()
    }

    func checkStreakBadges(streak: Int) {
        if streak >= 7  { unlock("streak_7") }
        if streak >= 30 { unlock("streak_30") }
        objectWillChange.send()
    }

    private func unlock(_ id: String) {
        var ids = unlockedIDs
        guard !ids.contains(id) else { return }
        ids.insert(id)
        unlockedIDs = ids
        // Bonus XP for the badge itself (no recursion risk — badge XP rewards don't trigger badge checks)
        if let badge = Self.allBadges.first(where: { $0.id == id }), badge.xpReward > 0 {
            totalXP += badge.xpReward
        }
    }
}
