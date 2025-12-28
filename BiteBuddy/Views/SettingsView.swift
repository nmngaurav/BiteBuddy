import SwiftUI
import SwiftData
import MessageUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userPrefs: [UserPreferences]
    
    // Feature Toggles (bound to SwiftData in onAppear/onChange)
    @State private var dailyGoal: Int = 2000
    @State private var waterGoal: Int = 2500
    @State private var hapticEnabled: Bool = true
    @State private var soundEnabled: Bool = true
    
    // Notification Toggles
    @State private var morningReminder: Bool = true
    @State private var lunchReminder: Bool = true
    @State private var waterReminder: Bool = true
    
    @State private var showMailError = false
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(10)
                            .background(Theme.Colors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    Text("Settings")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.leading, 10)
                    Spacer()
                }
                .padding(25)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // MARK: - Core Goals
                        SettingsSection(title: "MY GOALS") {
                            SettingsRow(icon: "target", color: Theme.Colors.primary, title: "Daily Calories") {
                                HStack {
                                    TextField("2000", value: $dailyGoal, format: .number)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Theme.Colors.primary)
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: 80)
                                    Text("kcal")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            
                            Divider().background(Theme.Colors.textTertiary.opacity(0.1))
                            
                            SettingsRow(icon: "drop.fill", color: Theme.Colors.secondary, title: "Water Target") {
                                HStack {
                                    TextField("2500", value: $waterGoal, format: .number)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Theme.Colors.secondary)
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: 80)
                                    Text("ml")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                        }
                        
                        // MARK: - App Experience
                        SettingsSection(title: "EXPERIENCE") {
                            ToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback", isOn: $hapticEnabled)
                            Divider().background(Theme.Colors.textTertiary.opacity(0.1))
                            ToggleRow(icon: "speaker.wave.2.fill", title: "Sound Effects", isOn: $soundEnabled)
                        }
                        
                        // MARK: - Reminders
                        SettingsSection(title: "REMINDERS") {
                            ToggleRow(icon: "sun.max.fill", title: "Morning Motivation (8 AM)", isOn: $morningReminder)
                            Divider().background(Theme.Colors.textTertiary.opacity(0.1))
                            ToggleRow(icon: "fork.knife", title: "Lunch Reminder (1 PM)", isOn: $lunchReminder)
                            Divider().background(Theme.Colors.textTertiary.opacity(0.1))
                            ToggleRow(icon: "drop.fill", title: "Hydration Alerts", isOn: $waterReminder)
                        }
                        
                        // MARK: - Support
                        SettingsSection(title: "SUPPORT") {
                            Button(action: { sendEmail(subject: "Feature Request") }) {
                                SettingsRowContent(icon: "lightbulb.fill", color: .yellow, title: "Suggest a Feature", showChevron: true)
                            }
                            
                            Divider().background(Theme.Colors.textTertiary.opacity(0.1))
                            
                            Button(action: { sendEmail(subject: "Support Needed") }) {
                                SettingsRowContent(icon: "envelope.fill", color: Theme.Colors.textPrimary, title: "Contact Support", showChevron: true)
                            }
                            
                            Divider().background(Theme.Colors.textTertiary.opacity(0.1))
                            
                            Button(action: { 
                                if let url = URL(string: "itms-apps://apple.com/app/idYOUR_APP_ID?action=write-review") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                SettingsRowContent(icon: "star.fill", color: .orange, title: "Rate Us", showChevron: true)
                            }
                        }
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("BiteBuddy v1.0.0")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.Colors.textTertiary)
                            Text("Made with ❤️ for Wellness")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.textTertiary.opacity(0.6))
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear { loadPrefs() }
        .onChange(of: dailyGoal) { savePrefs() }
        .onChange(of: waterGoal) { savePrefs() }
        .onChange(of: hapticEnabled) { savePrefs() }
        .onChange(of: soundEnabled) { savePrefs() }
        .onChange(of: morningReminder) { savePrefs() }
        .onChange(of: lunchReminder) { savePrefs() }
        .onChange(of: waterReminder) { savePrefs() }
        .alert("Cannot Send Email", isPresented: $showMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please configure a mail account in your settings.")
        }
    }
    
    private func loadPrefs() {
        if let prefs = userPrefs.first {
            dailyGoal = prefs.dailyGoal
            waterGoal = prefs.dailyWaterGoal
            hapticEnabled = prefs.hapticEnabled
            soundEnabled = prefs.soundEnabled
            morningReminder = prefs.morningReminderEnabled
            lunchReminder = prefs.lunchReminderEnabled
            waterReminder = prefs.waterReminderEnabled
        }
    }
    
    private func savePrefs() {
        if let prefs = userPrefs.first {
            prefs.dailyGoal = dailyGoal
            prefs.dailyWaterGoal = waterGoal
            prefs.hapticEnabled = hapticEnabled
            prefs.soundEnabled = soundEnabled
            prefs.morningReminderEnabled = morningReminder
            prefs.lunchReminderEnabled = lunchReminder
            prefs.waterReminderEnabled = waterReminder
            try? modelContext.save()
            
            // Update notification schedule
            NotificationManager.shared.scheduleDailyReminders()
        }
    }
    
    private func sendEmail(subject: String) {
        let recipient = "app.sandboxx@gmail.com"
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(recipient)?subject=\(subjectEncoded)"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailError = true
        }
    }
}

// MARK: - Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Theme.Colors.backgroundSecondary)
            .cornerRadius(16)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    let content: Content
    
    init(icon: String, color: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.color = color
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
            
            content
        }
        .frame(height: 30)
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                .labelsHidden()
        }
        .frame(height: 30)
    }
}

struct SettingsRowContent: View {
    let icon: String
    let color: Color
    let title: String
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .frame(height: 30)
    }
}
