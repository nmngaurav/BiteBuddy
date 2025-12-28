import Foundation

/// Hydration achievement badge
struct HydrationBadge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let requirement: BadgeRequirement
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    
    enum BadgeRequirement: Codable {
        case streak(days: Int)
        case totalGlasses(count: Int)
        case timeOfDay(beforeHour: Int, consecutiveDays: Int)
        case perfectWeek
    }
}

/// Water streak and achievement tracker
class WaterStreakManager {
    static let shared = WaterStreakManager()
    
    private let userDefaults = UserDefaults.standard
    private let streakKey = "waterStreak"
    private let lastGoalDateKey = "lastWaterGoalDate"
    private let unlockedBadgesKey = "unlockedBadges"
    
    // Available badges
    let allBadges: [HydrationBadge] = [
        HydrationBadge(
            id: "streak_3",
            name: "Getting Started",
            description: "3-day streak",
            emoji: "💧",
            requirement: .streak(days: 3)
        ),
        HydrationBadge(
            id: "streak_7",
            name: "Week Warrior",
            description: "7-day streak",
            emoji: "🔥",
            requirement: .streak(days: 7)
        ),
        HydrationBadge(
            id: "streak_30",
            name: "Hydration Hero",
            description: "30-day streak",
            emoji: "🏆",
            requirement: .streak(days: 30)
        ),
        HydrationBadge(
            id: "total_100",
            name: "Century Club",
            description: "100 total glasses",
            emoji: "💯",
            requirement: .totalGlasses(count: 100)
        ),
        HydrationBadge(
            id: "early_bird",
            name: "Early Bird",
            description: "3 glasses before noon (5 days)",
            emoji: "🌅",
            requirement: .timeOfDay(beforeHour: 12, consecutiveDays: 5)
        ),
        HydrationBadge(
            id: "perfect_week",
            name: "Perfect Week",
            description: "7/7 days hit goal",
            emoji: "⭐",
            requirement: .perfectWeek
        )
    ]
    
    private init() {}
    
    /// Get current streak count
    var currentStreak: Int {
        get { userDefaults.integer(forKey: streakKey) }
        set { userDefaults.set(newValue, forKey: streakKey) }
    }
    
    /// Get last date goal was achieved
    private var lastGoalDate: Date? {
        get { userDefaults.object(forKey: lastGoalDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastGoalDateKey) }
    }
    
    /// Check if user reached goal today and update streak
    func checkGoalReached(intake: Int, goal: Int) {
        guard intake >= goal else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if already counted today
        if let lastDate = lastGoalDate, calendar.isDate(lastDate, inSameDayAs: today) {
            return // Already counted
        }
        
        // Check if streak continues or breaks
        if let lastDate = lastGoalDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            
            if calendar.isDate(lastDate, inSameDayAs: yesterday) {
                // Streak continues
                currentStreak += 1
            } else {
                // Streak broken, restart
                currentStreak = 1
            }
        } else {
            // First time
            currentStreak = 1
        }
        
        lastGoalDate = today
        
        // Check for new badge unlocks
        checkBadgeUnlocks()
    }
    
    /// Get unlocked badges
    func getUnlockedBadges() -> [HydrationBadge] {
        guard let data = userDefaults.data(forKey: unlockedBadgesKey),
              let badges = try? JSONDecoder().decode([HydrationBadge].self, from: data) else {
            return []
        }
        return badges
    }
    
    /// Check and unlock new badges
    private func checkBadgeUnlocks() {
        var unlockedBadges = getUnlockedBadges()
        let unlockedIds = Set(unlockedBadges.map { $0.id })
        
        for var badge in allBadges where !unlockedIds.contains(badge.id) {
            if shouldUnlock(badge: badge) {
                badge.isUnlocked = true
                badge.unlockedDate = Date()
                unlockedBadges.append(badge)
                
                // Notify about new badge (post notification)
                NotificationCenter.default.post(
                    name: NSNotification.Name("BadgeUnlocked"),
                    object: badge
                )
            }
        }
        
        // Save unlocked badges
        if let data = try? JSONEncoder().encode(unlockedBadges) {
            userDefaults.set(data, forKey: unlockedBadgesKey)
        }
    }
    
    /// Check if badge should be unlocked
    private func shouldUnlock(badge: HydrationBadge) -> Bool {
        switch badge.requirement {
        case .streak(let days):
            return currentStreak >= days
        case .totalGlasses(let count):
            // This would need total glass tracking (future enhancement)
            return false
        case .timeOfDay(_, _):
            // This would need time tracking (future enhancement)
            return false
        case .perfectWeek:
            // This would need weekly tracking (future enhancement)
            return false
        }
    }
    
    /// Reset streak (for testing)
    func resetStreak() {
        currentStreak = 0
        lastGoalDate = nil
    }
}
