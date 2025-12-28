import SwiftData
import Foundation

@MainActor
class DataService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Core Logging
    
    func logMeal(summary: MealSummary, associatedMessageId: UUID? = nil, replacingMessageId: UUID? = nil) {
        // Resolve Target Date
        var targetDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let parsed = formatter.date(from: summary.date) {
            targetDate = parsed
        }
        
        let today = Calendar.current.startOfDay(for: targetDate)
        
        // 1. Find or Create DailyLog
        var dailyLog: DailyLog
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        
        let existingLogs = (try? modelContext.fetch(descriptor)) ?? []
        print("Persistence Audit: Found \(existingLogs.count) existing logs for \(today.formatted())")
        
        if let existingLog = existingLogs.first {
            dailyLog = existingLog
        } else {
            print("Persistence Audit: Creating NEW DailyLog for \(today.formatted())")
            dailyLog = DailyLog(date: today)
            modelContext.insert(dailyLog)
        }
        
        var mealEntryToUpdate: MealEntry?
        
        // STEP 1: DATABASE-FIRST DEDUPLICATION
        // Check if a meal of the SAME TYPE already exists on the SAME DATE
        // This prevents duplicate cards (e.g., two DINNER cards on Dec 27)
        let existingMealOfSameType = dailyLog.meals.first(where: { 
            $0.type.uppercased() == summary.mealType.uppercased() 
        })
        
        if let existing = existingMealOfSameType {
            print("⚠️ DEDUPLICATION: Found existing \(summary.mealType) on \(today.formatted()), UPDATING instead of creating duplicate")
            mealEntryToUpdate = existing
            
            // Subtract old values from daily totals
            dailyLog.totalCalories -= existing.totalCalories
            dailyLog.protein -= existing.protein
            dailyLog.carbs -= existing.carbs
            dailyLog.fats -= existing.fats
            
            // Clear old food items
            for item in existing.foodItems {
                modelContext.delete(item)
            }
            existing.foodItems.removeAll()
            
        // STEP 2: FALLBACK - Check chat context (for explicit edits via "Edit that meal")
        } else if let replaceId = replacingMessageId {
            if let existing = dailyLog.meals.first(where: { $0.associatedMessageId == replaceId }) {
                print("Persistence Audit: Editing existing meal entry (\(existing.type)) via chat context")
                mealEntryToUpdate = existing
                
                // Subtract old values
                dailyLog.totalCalories -= existing.totalCalories
                dailyLog.protein -= existing.protein
                dailyLog.carbs -= existing.carbs
                dailyLog.fats -= existing.fats
                
                for item in existing.foodItems {
                    modelContext.delete(item)
                }
                existing.foodItems.removeAll()
            }
        }
        
        let targetEntry: MealEntry
        
        if let existing = mealEntryToUpdate {
            existing.type = summary.mealType
            existing.totalCalories = summary.totalCalories
            existing.protein = summary.protein
            existing.carbs = summary.carbs
            existing.fats = summary.fats
            existing.associatedMessageId = associatedMessageId
            targetEntry = existing
        } else {
            print("Persistence Audit: Creating NEW meal entry (\(summary.mealType))")
            targetEntry = MealEntry(
                type: summary.mealType,
                totalCalories: summary.totalCalories,
                protein: summary.protein,
                carbs: summary.carbs,
                fats: summary.fats,
                associatedMessageId: associatedMessageId
            )
            targetEntry.dailyLog = dailyLog
            dailyLog.meals.append(targetEntry)
        }
        
        // 3. Create New Persistent Food Items
        for item in summary.items {
            let savedItem = SavedFoodItem(
                name: item.name,
                quantity: item.quantity,
                calories: item.calories
            )
            savedItem.mealEntry = targetEntry
            targetEntry.foodItems.append(savedItem)
        }
        
        // 4. Update Aggregates
        dailyLog.totalCalories += summary.totalCalories
        dailyLog.protein += summary.protein
        dailyLog.carbs += summary.carbs
        dailyLog.fats += summary.fats
        
        print("Persistence Audit: Final Daily Total for \(today.formatted()): \(dailyLog.totalCalories) kcal")
        
        // 5. Save with Error Handling
        do {
            try modelContext.save()
            print("✅ SUCCESS: Saved to database for \(today.formatted())")
        } catch {
            print("❌ CRITICAL ERROR: Failed to save meal: \(error)")
        }
    }
    
    func logWater(amount: Int, for date: Date = Date()) {
        let today = Calendar.current.startOfDay(for: date)
        
        // Find or create DailyLog
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        
        let existingLogs = (try? modelContext.fetch(descriptor)) ?? []
        let dailyLog: DailyLog
        
        if let existingLog = existingLogs.first {
            dailyLog = existingLog
        } else {
            dailyLog = DailyLog(date: today)
            modelContext.insert(dailyLog)
        }
        
        // Add water amount
        dailyLog.waterIntake += amount
        
        print("💧 Logged \(amount)ml water. Total: \(dailyLog.waterIntake)ml")
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save water log: \(error)")
        }
    }
    
    // MARK: - Analytics
    
    func getDailyStats(for date: Date = Date()) -> DailyLog? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < tomorrow }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func deleteMeal(entry: MealEntry) {
        guard let dailyLog = entry.dailyLog else { return }
        
        // Subtract from aggregates
        dailyLog.totalCalories -= entry.totalCalories
        dailyLog.protein -= entry.protein
        dailyLog.carbs -= entry.carbs
        dailyLog.fats -= entry.fats
        
        modelContext.delete(entry)
        try? modelContext.save()
    }
}
