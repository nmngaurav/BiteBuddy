import Foundation
import SwiftData
import SwiftUI

@Observable
class ChatViewModel {
    var messages: [Message] = []
    var isThinking: Bool = false
    var inputText: String = ""
    var dailyCalories: Int = 0
    var dailyGoal: Int = 2000 
    var suggestions: [String] = []
    var userPrefs: UserPreferences?
    var showOnboarding: Bool = false
    var isLoading: Bool = true  // Prevent flash during prefs load
    var showCelebration: Bool = false // Triggers confetti/haptics
    
    // PERSONA MANAGEMENT
    // Explicit tracking property for SwiftUI observation
    var selectedPersonaRawValue: String?
    
    var currentPersona: BuddyPersona {
        guard let stored = selectedPersonaRawValue ?? userPrefs?.selectedPersona else { 
            return .biteBuddy 
        }
        return BuddyPersona(rawValue: stored) ?? .biteBuddy
    }
    
    func updatePersona(_ persona: BuddyPersona) {
        userPrefs?.selectedPersona = persona.rawValue
        selectedPersonaRawValue = persona.rawValue
        try? modelContext?.save()
    }
    
    // STATE TRACKING: The ID of the message containing the current active meal summary
    var activeMealContextId: UUID?
    
    private let aiService: AIAssistant
    private var modelContext: ModelContext?
    
    init(aiService: AIAssistant = OpenAIService()) {
        self.aiService = aiService
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        self.dataService = DataService(modelContext: context)
        fetchUserPreferences()
        fetchMessages()
        fetchDailyStats()
        
        // Restore state: Find the last message with a summary to initialize active context
        if let lastSummary = messages.last(where: { !$0.isUser && $0.summaryData != nil }) {
            self.activeMealContextId = lastSummary.id
        }
    }
    
    private func fetchUserPreferences() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<UserPreferences>()
        do {
            let results = try context.fetch(descriptor)
            userPrefs = results.first
            if userPrefs == nil {
                showOnboarding = true
            } else {
                if userPrefs?.hasCompletedOnboarding == false {
                    showOnboarding = true
                }
                // Sync settings
                self.dailyGoal = userPrefs?.dailyGoal ?? 2000
                // Sync persona selection for proper UI tracking
                self.selectedPersonaRawValue = userPrefs?.selectedPersona
                print("✅ Synced daily goal: \(self.dailyGoal)")
                print("✅ Synced persona: \(selectedPersonaRawValue ?? "nil")")
            }
        } catch {
            print("Failed to fetch preferences: \(error)")
        }
        
        isLoading = false  // Prefs loaded, safe to show UI
    }
    
    func fetchMessages() {
        guard let context = modelContext else { return }
        if showOnboarding { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            messages = try context.fetch(descriptor)
            if messages.isEmpty {
                sendInitialGreeting()
            }
        } catch {
            print("Failed to fetch messages: \(error)")
        }
    }
    
    
    private func sendInitialGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        let name = userPrefs?.name ?? ""
        let prefix = name.isEmpty ? "" : "Hello \(name)! "
        
        switch hour {
        case 5..<11: greeting = "\(prefix)Good morning! What did you have for breakfast?"
        case 11..<16: greeting = "\(prefix)Hi! What's for lunch today?"
        case 16..<19: greeting = "\(prefix)Hey! Having an evening snack?"
        default: greeting = "\(prefix)Good evening! What did you have for dinner?"
        }
        
        let initialMsg = Message(content: greeting, isUser: false)
        addMessage(initialMsg)
    }
    
    
    @MainActor
    func sendMessage(_ text: String? = nil) {
        let content = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        let userMsg = Message(content: content, isUser: true)
        addMessage(userMsg)
        inputText = ""
        suggestions = [] // Clear suggestions on new message
        
        processAIResponse()
    }
    
    
    private var dataService: DataService?
    
    func fetchDailyStats() {
        if let stats = dataService?.getDailyStats() {
            dailyCalories = stats.totalCalories
        } else {
            dailyCalories = 0 // Start fresh if no log exists
        }
    }
    
    private func processAIResponse() {
        isThinking = true
        
        Task {
            do {
                // Get current context
                let currentLog = dataService?.getDailyStats()
                let response = try await aiService.getResponse(for: messages, userPrefs: userPrefs, dailyLog: currentLog)
                
                await MainActor.run {
                    var summaryJson: String? = nil
                    if let summary = response.summary {
                        summaryJson = try? String(data: JSONEncoder().encode(summary), encoding: .utf8)
                    }
                    
                    self.suggestions = response.suggestions
                    
                    // FALLBACK SUGGESTION LOGIC (Ghost Chip Fix)
                    if self.suggestions.isEmpty {
                        print("👻 Suggestions empty - generating fallbacks")
                        let fallbackChips = self.generateFallbackSuggestions(for: response.content)
                        self.suggestions = fallbackChips
                    }
                    print("🎯 Updated suggestions to: \(self.suggestions)")
                    
                    // WATER LOGGING (if AI returned water amount)
                    if let waterAmount = response.waterAmount {
                        print("💧 Logging water: \(waterAmount)ml")
                        dataService?.logWater(amount: waterAmount)
                        fetchDailyStats()
                    }
                    
                    // STATEFUL SESSION LOGIC
                    // Determine if we are replacing an existing meal or creating a new one.
                    var replacingMessageId: UUID? = nil
                    if let summary = response.summary {
                         // 1. Try the Explicit Active Context - BUT check if meal type matches
                         if let activeId = self.activeMealContextId,
                            let activeMsg = self.messages.first(where: { $0.id == activeId }),
                            let activeSummaryData = activeMsg.summaryData?.data(using: .utf8),
                            let activeSummary = try? JSONDecoder().decode(MealSummary.self, from: activeSummaryData) {
                             
                             // Only replace if it's the SAME meal type
                             if activeSummary.mealType == summary.mealType {
                                 replacingMessageId = activeId
                             }
                         } 
                         
                         // 2. Fallback: If no match, check if we're explicitly editing the VERY last message
                         if replacingMessageId == nil,
                            let lastSummaryMsg = self.messages.last(where: { !$0.isUser && $0.summaryData != nil }) {
                             
                             // If it's the same type, we might be refining it
                             if let lastData = lastSummaryMsg.summaryData?.data(using: .utf8),
                                let lastSummary = try? JSONDecoder().decode(MealSummary.self, from: lastData),
                                lastSummary.mealType == summary.mealType {
                                 replacingMessageId = lastSummaryMsg.id
                             }
                         }
                    }
                    
                    print("📝 AI Response content: '\(response.content)'")
                    print("📝 AI Summary: \(response.summary != nil ? "YES" : "NO")")
                    print("📝 AI Suggestions count: \(response.suggestions.count)")
                    
                    let aiMsg = Message(content: response.content, isUser: false, summaryData: summaryJson)
                    addMessage(aiMsg)
                    
                    if let summary = response.summary {
                        // LOG MEAL TO PERSISTENCE
                        dataService?.logMeal(
                            summary: summary, 
                            associatedMessageId: aiMsg.id,
                            replacingMessageId: replacingMessageId
                        )
                        fetchDailyStats() // Update UI from source of truth
                        
                        // UPDATE STATE: This new message becomes the Active Context
                        self.activeMealContextId = aiMsg.id
                    }
                    
                    print("✅ AI message added, suggestions should now be: \(self.suggestions)")
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = Message(content: "Sorry, I'm having trouble connecting right now. Please try again.", isUser: false)
                    addMessage(errorMsg)
                    isThinking = false
                }
            }
        }
    }
    
    
    private func addMessage(_ message: Message) {
        messages.append(message)
        modelContext?.insert(message)
        try? modelContext?.save()
    }
    
    // MARK: - Safety Systems
    
    private func generateFallbackSuggestions(for responseText: String) -> [String] {
        let text = responseText.lowercased()
        
        // PRIORITY 1: SPECIFIC FOOD/CONTAINER CONTEXT
        if text.contains("bowl") || text.contains("plate") {
            return ["Small Bowl", "Medium Bowl", "Large Bowl"]
        }
        
        if text.contains("glass") || text.contains("cup") {
            return ["Half Glass", "Full Glass", "Mug"]
        }
        
        // PRIORITY 2: QUANTITY/NUMBER QUESTIONS
        if text.contains("how many") || text.contains("number of") {
            // Check for specific food items to customize
            if text.contains("egg") {
                return ["1 egg", "2 eggs", "3 eggs"]
            }
            if text.contains("idli") || text.contains("roti") || text.contains("slice") {
                return ["1", "2", "3", "4"]
            }
            // Generic numeric
            return ["1", "2", "3", "4"]
        }
        
        // PRIORITY 3: SIZE/PORTION QUESTIONS
        if text.contains("size") || text.contains("portion") || text.contains("how much") {
            // Check if it's about solid food vs liquid
            if text.contains("sambhar") || text.contains("curry") || text.contains("dal") {
                return ["Small Bowl", "Medium Bowl", "Large Bowl"]
            }
            return ["Small", "Medium", "Large"]
        }
        
        // PRIORITY 4: CONFIRMATION FALLBACKS (After logging)
        if text.contains("logged") || text.contains("added") || text.contains("saved") {
            return ["Add Water", "View History", "Check Goal"]
        }
        
        // PRIORITY 5: GREETING/WELCOME FALLBACKS
        if text.contains("hello") || text.contains("hi") || text.contains("welcome") {
            return ["Log Breakfast", "Log Lunch", "Log Snack"]
        }
        
        // PRIORITY 6: GENERIC SAFETY NET (NO GUESSING)
        // If we don't know the context, do NOT guess "Wheat/White" (fixes Fruit Salad bug)
        return ["Log Meal", "View History", "My Goal"]
    }
}
