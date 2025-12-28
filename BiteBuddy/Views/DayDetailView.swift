import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let log: DailyLog
    let goal: Int
    @Environment(\.dismiss) var dismiss
    
    var progress: Double {
        Double(log.totalCalories) / Double(goal)
    }
    
    var isOverGoal: Bool {
        log.totalCalories > goal
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date.formatted(.dateTime.month().day()))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                .padding(25)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Total Calories Card
                        VStack(spacing: 15) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TOTAL")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Theme.Colors.textTertiary)
                                    Text("\(log.totalCalories)")
                                        .font(.system(size: 48, weight: .black, design: .rounded))
                                        .foregroundColor(isOverGoal ? Theme.Colors.warning : Theme.Colors.primary)
                                    Text("KCAL")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("GOAL")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Theme.Colors.textTertiary)
                                    Text("\(goal)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.Colors.backgroundSecondary)
                                        .frame(height: 12)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isOverGoal ? Theme.Colors.warning : Theme.Colors.primary)
                                        .frame(width: min(geometry.size.width * progress, geometry.size.width), height: 12)
                                }
                            }
                            .frame(height: 12)
                            
                            Text("\(Int(progress * 100))% of goal")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(20)
                        .background(Theme.Colors.backgroundSecondary)
                        .cornerRadius(20)
                        
                        // Macros
                        HStack(spacing: 12) {
                            MacroCard(label: "PROTEIN", value: log.protein, unit: "g", color: Theme.Colors.secondary)
                            MacroCard(label: "CARBS", value: log.carbs, unit: "g", color: Theme.Colors.secondary)
                            MacroCard(label: "FATS", value: log.fats, unit: "g", color: Theme.Colors.secondary)
                        }
                        
                        // Meals
                        if !log.meals.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("MEALS")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Theme.Colors.textTertiary)
                                
                                ForEach(log.meals.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { meal in
                                    MealCard(meal: meal)
                                }
                            }
                        }
                    }
                    .padding(25)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

struct MacroCard: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(unit)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Theme.Colors.backgroundSecondary)
        .cornerRadius(16)
    }
}

struct MealCard: View {
    let meal: MealEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.type.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Theme.Colors.secondary)
                    Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
                
                Text("\(meal.totalCalories)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("kcal")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.top, 8)
            }
            
            // Food items
            if !meal.foodItems.isEmpty {
                VStack(spacing: 8) {
                    ForEach(meal.foodItems, id: \.id) { item in
                        HStack {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
                            Text("(\(item.quantity))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.textTertiary)
                            Spacer()
                            Text("\(item.calories)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Macros mini
            HStack(spacing: 12) {
                MealMacro(label: "P", value: meal.protein)
                MealMacro(label: "C", value: meal.carbs)
                MealMacro(label: "F", value: meal.fats)
            }
        }
        .padding(16)
        .background(Theme.Colors.backgroundSecondary)
        .cornerRadius(16)
    }
}

struct MealMacro: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
            Text("\(Int(value))g")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}
