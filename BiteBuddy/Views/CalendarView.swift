import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Fetch logs (sorted by date)
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @Query private var userPrefs: [UserPreferences]
    
    // State
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var showDayDetail = false
    @State private var showGoalEditor = false
    
    // Constants
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
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
                    
                    Text("History")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.leading, 10)
                    
                    Spacer()
                    
                    // Editable Goal
                    Button(action: { showGoalEditor = true }) {
                        HStack(spacing: 6) {
                            Text("GOALS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                            
                            Image(systemName: "target")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(25)
                .background(Theme.Colors.backgroundPrimary)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // MONTHLY CALENDAR
                        VStack(spacing: 20) {
                            // Month Header
                            HStack {
                                Text(currentMonth.formatted(.dateTime.month().year()))
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Spacer()
                                
                                HStack(spacing: 15) {
                                    Button(action: { 
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            changeMonth(by: -1) 
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    Button(action: { 
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            changeMonth(by: 1) 
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 25)
                            
                            // Day Labels
                            HStack(spacing: 0) {
                                ForEach(days, id: \.self) { day in
                                    Text(day.uppercased())
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Theme.Colors.textTertiary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 25)
                            
                            // Calendar Grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                                ForEach(calendarDays, id: \.self) { date in
                                    if let date = date {
                                        let log = getLog(for: date)
                                        DayCell(
                                            date: date, 
                                            log: log, 
                                            goal: userPrefs.first?.dailyGoal ?? 2000, 
                                            isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                            isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
                                        )
                                        .onTapGesture {
                                            if log != nil {
                                                selectedDate = date
                                                showDayDetail = true
                                            }
                                        }
                                    } else {
                                        // Empty Day Interaction
                                        Button(action: {
                                            // Haptic & Visual Feedback for empty state
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.warning)
                                            withAnimation(.default) {
                                                // Trigger shake (could add state for shake here if strictly needed, 
                                                // but for now relying on haptic is good first step)
                                            }
                                        }) {
                                            Color.clear.frame(height: 50)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Theme.Colors.textTertiary.opacity(0.1), lineWidth: 1)
                                                        .frame(width: 4, height: 4)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 25)
                        }
                        
                        // MONTHLY INSIGHTS
                        if !monthlyLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("MONTHLY INSIGHTS")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Theme.Colors.textTertiary)
                                    .padding(.horizontal, 25)
                                
                                // Average Card
                                MonthlyAverageCard(avg: averageCalories)
                                    .padding(.horizontal, 25)
                                
                                HStack(spacing: 15) {
                                    InsightCard(title: "HIGHEST DAY", value: "\(maxCalories)", date: maxCalorieDate, color: Theme.Colors.warning)
                                    InsightCard(title: "LOWEST DAY", value: "\(minCalories)", date: minCalorieDate, color: Theme.Colors.primary)
                                }
                                .padding(.horizontal, 25)
                                
                                // Selected Day Stats (if clicked)
                                if let selected = selectedDate, let log = getLog(for: selected) {
                                    SelectedDayStatsCard(date: selected, log: log)
                                        .padding(.horizontal, 25)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let date = selectedDate, let log = getLog(for: date) {
                DayDetailView(date: date, log: log, goal: userPrefs.first?.dailyGoal ?? 2000)
            }
        }
        .sheet(isPresented: $showGoalEditor) {
            GoalEditorSheet()
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .environment(\.modelContext, modelContext)
        }
    }
    
    // MARK: - Helpers
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDay = interval.start
        
        let weekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        var days: [Date?] = Array(repeating: nil, count: weekday - 1)
        
        for i in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDay) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func getLog(for date: Date) -> DailyLog? {
        logs.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private var monthlyLogs: [DailyLog] {
        logs.filter { Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month) }
    }
    
    private var maxCalories: Int {
        monthlyLogs.map { $0.totalCalories }.max() ?? 0
    }
    
    private var maxCalorieDate: Date? {
        monthlyLogs.max(by: { $0.totalCalories < $1.totalCalories })?.date
    }
    
    private var minCalories: Int {
        monthlyLogs.map { $0.totalCalories }.min() ?? 0
    }
    
    private var minCalorieDate: Date? {
        monthlyLogs.min(by: { $0.totalCalories < $1.totalCalories })?.date
    }
    
    private var averageCalories: Int {
        let total = monthlyLogs.reduce(0) { $0 + $1.totalCalories }
        return monthlyLogs.isEmpty ? 0 : total / monthlyLogs.count
    }
}

// MARK: - Components

struct DayCell: View {
    let date: Date
    let log: DailyLog?
    let goal: Int
    let isCurrentMonth: Bool
    let isSelected: Bool
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let total = log?.totalCalories ?? 0
        let hasData = total > 0
        let isOver = total > goal
        
        // Water tracking
        let waterIntake = log?.waterIntake ?? 0
        let waterGoal = 2500 // Default goal, could be passed as parameter
        let waterPercentage = waterGoal > 0 ? Double(waterIntake) / Double(waterGoal) : 0.0
        let hasWater = waterIntake > 0
        
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .black : .bold))
                .foregroundColor(isCurrentMonth ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
            
            if hasData {
                Text("\(total)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isOver ? Theme.Colors.warning : Theme.Colors.primary)
            } else {
                // Visual cue for empty past days
                if date < Date() && !isToday {
                    Circle()
                        .stroke(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Theme.Colors.backgroundSecondary)
                        .frame(width: 4, height: 4)
                }
            }
            
            // Water Indicator (bottom dot)
            if hasWater {
                Circle()
                    .fill(Theme.Colors.secondary.opacity(waterPercentage > 0.75 ? 1.0 : 0.5))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isSelected ? Theme.Colors.primary.opacity(0.2) :
                    isToday ? Theme.Colors.backgroundSecondary :
                    hasData && isOver ? Theme.Colors.warning.opacity(0.1) :
                    hasData && !isOver ? Theme.Colors.primary.opacity(0.08) :
                    Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Theme.Colors.primary :
                    isToday ? Theme.Colors.primary.opacity(0.3) :
                    hasData && isOver ? Theme.Colors.warning.opacity(0.3) :
                    Color.clear,
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let date: Date?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(color)
                
                if let date = date {
                    Text(date.formatted(.dateTime.day().month()))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.backgroundSecondary)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct MonthlyAverageCard: View {
    let avg: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MONTHLY AVERAGE")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Theme.Colors.textTertiary)
                Text("\(avg)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                + Text(" kcal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            // Mini Graph Icon
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.primary)
                .padding(12)
                .background(Theme.Colors.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(20)
        .background(Theme.Colors.backgroundSecondary)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.Colors.textTertiary.opacity(0.1), lineWidth: 1))
    }
}

struct SelectedDayStatsCard: View {
    let date: Date
    let log: DailyLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("Daily Breakdown")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                Spacer()
                Text("\(log.totalCalories)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Divider().background(Theme.Colors.textTertiary.opacity(0.2))
            
            HStack(spacing: 0) {
                MacroMiniItem(label: "Protein", value: "\(Int(log.protein))g", color: Theme.Colors.secondary)
                Spacer()
                MacroMiniItem(label: "Carbs", value: "\(Int(log.carbs))g", color: Theme.Colors.secondary)
                Spacer()
                MacroMiniItem(label: "Fats", value: "\(Int(log.fats))g", color: Theme.Colors.secondary)
            }
            
            // Water Intake Row
            if log.waterIntake > 0 {
                Divider().background(Theme.Colors.textTertiary.opacity(0.2))
                
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondary)
                    Text("Water Intake")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(log.waterIntake) ml")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.secondary)
                }
            }
        }
        .padding(20)
        .background(Theme.Colors.backgroundSecondary)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1))
    }
}

struct MacroMiniItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(color)
        }
    }
}

struct GoalEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userPrefs: [UserPreferences]
    
    // Sliders
    @State private var calorieGoal: Double = 2000
    @State private var waterGoal: Double = 2500
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Daily Goals")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Spacer()
                    Button("Save") {
                        saveGoals()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)
                
                ScrollView {
                    VStack(spacing: 40) {
                        
                        // Calorie Goal Section
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(Theme.Colors.primary)
                                    .font(.system(size: 20))
                                Text("Calories")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                Text("\(Int(calorieGoal)) kcal")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                            
                            // Custom Slider
                            Slider(value: $calorieGoal, in: 1200...4000, step: 50)
                                .accentColor(Theme.Colors.primary)
                                .padding(.vertical, 10)
                            
                            HStack {
                                Text("1200")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.textTertiary)
                                Spacer()
                                Text("4000+")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(.top, -10)
                        }
                        .padding(25)
                        .background(Theme.Colors.backgroundSecondary)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Water Goal Section
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(Theme.Colors.secondary)
                                    .font(.system(size: 20))
                                Text("Hydration")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                Text("\(Int(waterGoal)) ml")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.Colors.secondary)
                            }
                            
                            // Custom Slider
                            Slider(value: $waterGoal, in: 1000...4000, step: 250)
                                .accentColor(Theme.Colors.secondary)
                                .padding(.vertical, 10)
                            
                            HStack {
                                Text("1000")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.textTertiary)
                                Spacer()
                                Text("4000+")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(.top, -10)
                        }
                        .padding(25)
                        .background(Theme.Colors.backgroundSecondary)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.Colors.secondary.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Tip Card
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Pro Tip")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Text("Consistent goals help the AI provide better recommendations over time.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .lineLimit(nil)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.backgroundSecondary.opacity(0.5))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 25)
                }
            }
        }
        .onAppear {
            if let prefs = userPrefs.first {
                calorieGoal = Double(prefs.dailyGoal)
                // Assuming water goal exists, strictly speaking we need to add it to UserPreferences first
                // For now, defaulting to standard if not persisted
            }
        }
    }
    
    private func saveGoals() {
        if let prefs = userPrefs.first {
            prefs.dailyGoal = Int(calorieGoal)
            // Save water goal too if property exists
            try? modelContext.save()
        }
        
        dismiss()
    }
}
