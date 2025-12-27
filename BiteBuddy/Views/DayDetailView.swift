import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    @Query private var dayLogs: [DailyLog]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal: MealEntry? = nil
    var dismissAll: (() -> Void)? = nil
    
    // We filter properly in the init
    init(date: Date, dismissAll: (() -> Void)? = nil) {
        self.date = date
        self.dismissAll = dismissAll
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _dayLogs = Query(filter: #Predicate<DailyLog> { log in
            log.date >= startOfDay && log.date < endOfDay
        })
    }
    
    var dailyLog: DailyLog? {
        dayLogs.first
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8FAFC").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "0F172A"))
                    }
                    
                    Spacer()
                    
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color(hex: "0F172A"))
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Image(systemName: "chevron.left").opacity(0)
                        .frame(width: 20)
                }
                .padding()
                .background(Color.white)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "E2E8F0")), alignment: .bottom)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let log = dailyLog, !log.meals.isEmpty {
                            // Summary Card
                            DailySummaryHeader(log: log)
                            
                            // Meal List
                            VStack(spacing: 16) {
                                ForEach(log.meals.sorted(by: { $0.timestamp < $1.timestamp })) { meal in
                                    Button(action: { selectedMeal = meal }) {
                                        MealEntryRow(meal: meal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteMeal(meal)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(hex: "E2E8F0"))
                                
                                Text("Quiet Day for Your Palette")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(Color(hex: "0F172A"))
                                
                                Text("You haven't logged any meals for this date yet. Your future self will thank you for the data!")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "64748B"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button(action: {
                                    if let dismissAll = dismissAll {
                                        dismissAll()
                                    } else {
                                        dismiss()
                                    }
                                }) {
                                    Text("START LOGGING")
                                        .font(.system(size: 12, weight: .black))
                                        .padding(.horizontal, 25)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "4F46E5"))
                                        .foregroundColor(.white)
                                        .cornerRadius(25)
                                }
                                .padding(.top, 10)
                            }
                            .padding(.top, 100)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailSheet(meal: meal)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            print("DayDetailView appeared for date: \(date.formatted()). Found logs: \(dayLogs.count)")
        }
    }
    
    private func deleteMeal(_ meal: MealEntry) {
        guard let log = dailyLog else { return }
        
        // Update aggregates
        log.totalCalories -= meal.totalCalories
        log.protein -= meal.protein
        log.carbs -= meal.carbs
        log.fats -= meal.fats
        
        modelContext.delete(meal)
        try? modelContext.save()
    }
}

struct DailySummaryHeader: View {
    let log: DailyLog
    
    var body: some View {
        VStack(spacing: 12) {
            Text("DAILY TOTAL")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color(hex: "94A3B8"))
                .kerning(1.5)
            
            Text("\(log.totalCalories)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "0F172A"))
            
            HStack(spacing: 20) {
                MacroPill(label: "P", value: log.protein, color: Color(hex: "4F46E5"))
                MacroPill(label: "C", value: log.carbs, color: Color(hex: "4F46E5"))
                MacroPill(label: "F", value: log.fats, color: Color(hex: "4F46E5"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
            Text("\(Int(value))g")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "0F172A"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MealEntryRow: View {
    let meal: MealEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.type.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(hex: "4F46E5"))
                
                Text("\(meal.totalCalories) kcal")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "0F172A"))
                
                // Construct summary string
                let itemsList = meal.foodItems.map { $0.name }.joined(separator: ", ")
                Text(itemsList)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "64748B"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "CBD5E1"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
struct MealDetailSheet: View {
    let meal: MealEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Header with Macros
                VStack(spacing: 15) {
                    Text(meal.type.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color(hex: "4F46E5"))
                        .kerning(2)
                    
                    Text("\(meal.totalCalories) KCAL")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "0F172A"))
                }
                .padding(.top)
                
                Divider()
                
                // Items List
                VStack(alignment: .leading, spacing: 20) {
                    Text("BREAKDOWN")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Color(hex: "94A3B8"))
                        .kerning(1)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(meal.foodItems) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name.capitalized)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(hex: "1E293B"))
                                        Text(item.quantity)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(hex: "64748B"))
                                    }
                                    Spacer()
                                    Text("\(item.calories) kcal")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(Color(hex: "4F46E5"))
                                }
                                .padding(.vertical, 8)
                                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "F1F5F9")), alignment: .bottom)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
