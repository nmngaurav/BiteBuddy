import UserNotifications
import UIKit
import Combine

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleDailyReminders()
                }
            }
        }
    }
    
    func scheduleDailyReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // Fetch user preferences to determine which reminders to schedule
        let prefs = getUserPreferences()
        
        // 1. Morning Motivation (8:00 AM)
        if prefs?.morningReminderEnabled ?? true {
            scheduleNotification(
                id: "daily_morning",
                title: "Good Morning! ☀️",
                body: "Ready to fuel your day? Log your breakfast to stay on track!",
                hour: 8,
                minute: 0
            )
        }
        
        // 2. Lunch Reminder (1:00 PM)
        if prefs?.lunchReminderEnabled ?? true {
            scheduleNotification(
                id: "daily_lunch",
                title: "Lunch Time 🥗",
                body: "What's on the menu? Don't forget to track your meal.",
                hour: 13,
                minute: 0
            )
        }
        
        // 3. Water Reminders (if enabled)
        if prefs?.waterReminderEnabled ?? true {
            // Water Check 1 (10:30 AM)
            scheduleNotification(
                id: "water_morning",
                title: "Hydration Check 💧",
                body: "Sip sip! Have you had enough water yet?",
                hour: 10,
                minute: 30
            )
            
            // Water Check 2 (3:30 PM)
            scheduleNotification(
                id: "water_afternoon",
                title: "Stay Hydrated 💧",
                body: "A glass of water now boosts your energy for the rest of the day.",
                hour: 15,
                minute: 30
            )
        }
    }
    
    private func getUserPreferences() -> UserPreferences? {
        // This is a simplified fetch - in a real app, you'd inject ModelContext
        // For now, we'll return nil and default to `true` for all toggles
        // The actual persistence is handled by SettingsView calling this method after saving
        return nil
    }
    
    private func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
