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
                    
                    // Simple Stats (Goal)
                    if let goal = userPrefs.first?.dailyGoal {
                        VStack(alignment: .trailing) {
                            Text("GOAL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(Theme.Colors.textTertiary)
                            Text("\(goal)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(Theme.Colors.primary)
                        }
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
                                    Button(action: { changeMonth(by: -1) }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    Button(action: { changeMonth(by: 1) }) {
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
                                        DayCell(date: date, log: log, goal: userPrefs.first?.dailyGoal ?? 2000, isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month))
                                            .onTapGesture {
                                                selectedDate = date
                                            }
                                    } else {
                                        Color.clear.frame(height: 40)
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
                                
                                HStack(spacing: 15) {
                                    InsightCard(title: "MAX KCAL", value: "\(maxCalories)", date: maxCalorieDate, color: Theme.Colors.warning)
                                    InsightCard(title: "MIN KCAL", value: "\(minCalories)", date: minCalorieDate, color: Theme.Colors.primary)
                                }
                                .padding(.horizontal, 25)
                            }
                        }
                        
                        // SELECTED DAY DETAIL (Mini View)
                        if let selected = selectedDate, let log = getLog(for: selected) {
                            VStack(alignment: .leading, spacing: 15) {
                                Text(selected.formatted(date: .long, time: .omitted).uppercased())
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Theme.Colors.textTertiary)
                                    .padding(.horizontal, 25)
                                    .padding(.top, 10)
                                
                                DaySummaryCard(log: log)
                                    .padding(.horizontal, 25)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
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
}

// MARK: - Components

struct DayCell: View {
    let date: Date
    let log: DailyLog?
    let goal: Int
    let isCurrentMonth: Bool
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let total = log?.totalCalories ?? 0
        let percent = Double(total) / Double(goal)
        let isOver = total > goal
        
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .black : .bold))
                .foregroundColor(isCurrentMonth ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
            
            if total > 0 {
                Text("\(total)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isOver ? Theme.Colors.warning : Theme.Colors.primary)
            } else {
                Circle()
                    .fill(Theme.Colors.backgroundSecondary)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isToday ? Theme.Colors.backgroundSecondary : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Theme.Colors.primary : Color.clear, lineWidth: 1)
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

struct DaySummaryCard: View {
    let log: DailyLog
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DAILY TOTAL")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
                Text("\(log.totalCalories) KCAL")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .padding(20)
            .background(Theme.Colors.backgroundSecondary)
            
            // Macros
            HStack {
                Spacer()
                MacroPill(label: "P", value: log.protein)
                Spacer()
                MacroPill(label: "C", value: log.carbs)
                Spacer()
                MacroPill(label: "F", value: log.fats)
                Spacer()
            }
            .padding(15)
            .background(Theme.Colors.backgroundPrimary.opacity(0.5))
        }
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.Colors.backgroundSecondary, lineWidth: 1))
    }
}

struct MacroPill: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
            Text("\(Int(value))g")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }
}
