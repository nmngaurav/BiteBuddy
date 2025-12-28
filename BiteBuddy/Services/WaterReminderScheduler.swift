import Foundation
import UserNotifications
import Combine

/// Smart water reminder scheduler with adaptive timing
class WaterReminderScheduler: ObservableObject {
    static let shared = WaterReminderScheduler()
    
    @Published var isEnabled: Bool = false
    @Published var reminderInterval: TimeInterval = 5400 // 90 minutes default
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var lastWaterLogTime: Date?
    private var snoozeCount: Int = 0
    
    // Active hours (7 AM - 10 PM by default)
    var activeStartHour: Int = 7
    var activeEndHour: Int = 22
    
    private init() {
        checkNotificationPermission()
    }
    
    /// Check current notification authorization status
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permission from user
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isEnabled = granted
                completion(granted)
                
                if granted {
                    self.scheduleNextReminder()
                }
            }
        }
    }
    
    /// Schedule the next water reminder based on adaptive timing
    func scheduleNextReminder() {
        guard isEnabled else { return }
        
        // Cancel existing reminders
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Check if we're in active hours
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        guard hour >= activeStartHour && hour < activeEndHour else {
            // Schedule for next morning
            scheduleForNextMorning()
            return
        }
        
        // Adaptive interval based on snooze count
        var interval = reminderInterval
        if snoozeCount >= 2 {
            interval = 7200 // 2 hours if ignored 2x
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder 💧"
        content.body = contextualMessage()
        content.sound = UNNotificationSound(named: UNNotificationSoundName("reminder_gentle.wav"))
        content.categoryIdentifier = "WATER_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "water_reminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("⚠️ Failed to schedule reminder: \(error)")
            }
        }
    }
    
    /// Update schedule when user logs water
    func handleWaterLogged() {
        lastWaterLogTime = Date()
        snoozeCount = 0 // Reset snooze count on successful log
        scheduleNextReminder()
    }
    
    /// Handle snooze action
    func handleSnooze() {
        snoozeCount += 1
        // Schedule reminder for 30 minutes from now
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder 💧"
        content.body = "Time for a water break!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("reminder_gentle.wav"))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false) // 30 min
        let request = UNNotificationRequest(identifier: "water_reminder_snooze", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    /// Get contextual message based on time of day
    private func contextualMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning! Start your day with a glass of water 💧"
        case 12..<17:
            return "You're doing great! Time for a water break ✨"
        case 17..<22:
            return "Almost there! One more glass before bed 🌙"
        default:
            return "Stay hydrated! Time for some water 💧"
        }
    }
    
    /// Schedule reminder for next morning (7 AM)
    private func scheduleForNextMorning() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = activeStartHour
        components.minute = 0
        
        guard let morningTime = calendar.date(from: components) else { return }
        
        // If it's already past 7 AM today, schedule for tomorrow
        let scheduledTime = morningTime < Date() 
            ? calendar.date(byAdding: .day, value: 1, to: morningTime)! 
            : morningTime
        
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! 💧"
        content.body = "Start your day hydrated! Ready for your first glass?"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("reminder_gentle.wav"))
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "water_reminder_morning", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    /// Disable reminders
    func disableReminders() {
        isEnabled = false
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
