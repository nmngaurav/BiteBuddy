import Foundation
import SwiftData

@Model
final class Message: Identifiable {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var summaryData: String? // JSON encoded MealSummary if applicable
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), summaryData: String? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.summaryData = summaryData
    }
}

@Model
final class UserPreferences: Identifiable {
    var id: UUID
    var name: String
    var dailyGoal: Int
    var dietType: String // e.g., Vegetarian, Keto, None
    var allergies: String
    var favoriteCuisines: String
    var hasCompletedOnboarding: Bool
    
    // Phase 2: Goal Intelligence (Optional for migration safety)
    var goalType: String? // "Weight Loss", "Maintain", "Muscle Gain"
    var activityLevel: String? // "Sedentary", "Active", "Very Active"
    var selectedPersona: String? // "BiteBuddy", "Titan", "Lumi"
    
    init(id: UUID = UUID(), 
         name: String = "", 
         dailyGoal: Int = 2000, 
         dietType: String = "None", 
         allergies: String = "", 
         favoriteCuisines: String = "",
         hasCompletedOnboarding: Bool = false,
         goalType: String? = "Maintain",
         activityLevel: String? = "Active",
         selectedPersona: String? = "BiteBuddy") {
        self.id = id
        self.name = name
        self.dailyGoal = dailyGoal
        self.dietType = dietType
        self.allergies = allergies
        self.favoriteCuisines = favoriteCuisines
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.goalType = goalType
        self.activityLevel = activityLevel
        self.selectedPersona = selectedPersona
    }
}

enum BuddyPersona: String, CaseIterable, Codable {
    case biteBuddy = "BiteBuddy"
    case titan = "Titan"
    case lumi = "Lumi"
    
    var displayName: String {
        switch self {
        case .biteBuddy: return "BiteBuddy"
        case .titan: return "Coach Titan"
        case .lumi: return "Chef Lumi"
        }
    }
    
    var iconName: String {
        switch self {
        case .biteBuddy: return "leaf.fill" // Was "avocado_buddy"
        case .titan: return "dumbbell.fill" // Was "titan_coach"
        case .lumi: return "carrot.fill" // Was "lumi_chef"
        }
    }
    
    var description: String {
        switch self {
        case .biteBuddy: return "Your chill, vibey nutrition friend. Takes life easy."
        case .titan: return "Strict, high-energy performance coach. Demands results."
        case .lumi: return "Gentle, mindful nutritionist. Focuses on health & balance."
        }
    }
}

struct MealSummary: Codable {
    let mealType: String
    let totalCalories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let items: [FoodItem]
    let date: String? // Optional YYYY-MM-DD
}

struct FoodItem: Codable, Identifiable {
    var id: String { name }
    let name: String
    let quantity: String
    let calories: Int
}

// MARK: - Phase 2 Persistence Models

@Model
final class DailyLog: Identifiable {
    var id: UUID
    var date: Date // Normalized to start of day
    var totalCalories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    
    @Relationship(deleteRule: .cascade) var meals: [MealEntry] = []
    
    init(id: UUID = UUID(), date: Date, totalCalories: Int = 0, protein: Double = 0, carbs: Double = 0, fats: Double = 0) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date) // Force normalization
        self.totalCalories = totalCalories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
}

@Model
final class MealEntry: Identifiable {
    var id: UUID
    var timestamp: Date
    var type: String // Breakfast, Lunch, Dinner, Snack
    var totalCalories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var associatedMessageId: UUID?
    
    @Relationship(deleteRule: .cascade) var foodItems: [SavedFoodItem] = []
    var dailyLog: DailyLog?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), type: String, totalCalories: Int, protein: Double, carbs: Double, fats: Double, associatedMessageId: UUID? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.totalCalories = totalCalories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.associatedMessageId = associatedMessageId
    }
}

@Model
final class SavedFoodItem: Identifiable {
    var id: UUID
    var name: String
    var quantity: String
    var calories: Int
    var mealEntry: MealEntry?
    
    init(id: UUID = UUID(), name: String, quantity: String, calories: Int) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.calories = calories
    }
}
