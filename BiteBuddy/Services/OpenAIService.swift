import Foundation

class OpenAIService: AIAssistant {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Read API key from environment variable or use empty string
        // You should set OPENAI_API_KEY in your environment or use a secure config file
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        if self.apiKey.isEmpty {
            print("⚠️ WARNING: OPENAI_API_KEY environment variable not set")
        }
    }
    
    func getResponse(for messages: [Message], userPrefs: UserPreferences?, dailyLog: DailyLog? = nil) async throws -> (content: String, summary: MealSummary?, suggestions: [String]) {
        
        // Context Construction
        let userName = (userPrefs?.name ?? "").trimmingCharacters(in: .whitespaces)
        let dietInfo = userPrefs?.dietType ?? "None"
        let allergies = userPrefs?.allergies ?? "None"
        let cuisines = userPrefs?.favoriteCuisines ?? "None"
        let goalType = userPrefs?.goalType ?? "Maintain"
        let dailyGoal = userPrefs?.dailyGoal ?? 2000
        
        // Progress Context
        let currentCals = dailyLog?.totalCalories ?? 0
        let remainingCals = dailyGoal - currentCals
        let progressContext = "Today: \(currentCals) / \(dailyGoal) kcals. Remaining: \(remainingCals)."
        
        // EDIT CONTEXT: Detect if we're editing an existing meal
        var editContext = ""
        if let lastMessage = messages.last(where: { !$0.isUser && $0.summaryData != nil }),
           let summaryData = lastMessage.summaryData,
           let data = summaryData.data(using: .utf8),
           let previousMeal = try? JSONDecoder().decode(MealSummary.self, from: data) {
            
            // Build baseline for editing (Include Macros to prevent erosion)
            let itemsDesc = previousMeal.items.map { "\($0.name): \($0.calories) kcal" }.joined(separator: ", ")
            editContext = """
            
            EDIT MODE ACTIVE:
            You are editing this PREVIOUS MEAL:
            - Total: \(previousMeal.totalCalories) kcal (P: \(previousMeal.protein)g, C: \(previousMeal.carbs)g, F: \(previousMeal.fats)g)
            - Items: \(itemsDesc)
            
            CARDINAL RULES FOR EDITING:
            1. PRESERVE ALL items from the previous meal EXACTLY as listed above.
            2. ONLY update items the user explicitly mentions.
            3. PRESERVE MACROS: Keep the same protein, carbs, and fats for unmentioned items.
            4. If user adds a new item, append it and estimate its macros.
            5. Recalculate all totals (Cals, P, C, F) based on changes.
            6. ZERO LATENCY: You MUST include the full <SUMMARY> tag representing the NEW state immediately. Do NOT say "I will update". Just send the summary.
            """
        }
        
        // Resolve Persona
        let personaString = userPrefs?.selectedPersona ?? "BiteBuddy"
        let currentPersona = BuddyPersona(rawValue: personaString) ?? .biteBuddy
        
        var tonePrompt = ""
        switch currentPersona {
        case .biteBuddy:
            tonePrompt = """
            BUDDY TONE (Identity: BiteBuddy 🥑):
            - You are a chill, 'vibey' friend.
            - Use emojis like 🥗, 🤙, 🥑.
            - Be supportive but relaxed. "You got this."
            """
        case .titan:
            tonePrompt = """
            BUDDY TONE (Identity: Coach Titan 🏋️‍♂️):
            - You are a STRICT, high-energy athletic coach.
            - Use emojis like 🔥, 🛑, 👊, ⚠️.
            - Be direct. Demand discipline. Call out excuses. "No pain, no gain."
            """
        case .lumi:
            tonePrompt = """
            BUDDY TONE (Identity: Chef Lumi 👩‍🍳):
            - You are a gentle, mindful nutritionist.
            - Use emojis like ✨, 🍵, 🌱, 🥣.
            - Focus on food quality, flavor, and holistic balance. "Nourish yourself."
            """
        }
        
        let systemPrompt = """
        You are \(currentPersona.displayName), a PROACTIVE and INTELLIGENT "Nutrition Coach".
        \(userName.isEmpty ? "You are speaking to a user." : "You are speaking to \(userName). Use their name occasionally to build rapport.")
        
        TODAY IS: \(Date().formatted(date: .long, time: .standard))
        CURRENT TIME: \(Date().formatted(date: .omitted, time: .shortened))
        
        USER PROFILE:
        - Name: \(userName.isEmpty ? "Not provided" : userName) (If name is provided, use it naturally. If not, simply don't use a name - no placeholders like \"User\" or \"Buddy\".)
        - Goal: \(goalType) (Target: \(dailyGoal) kcal)
        - Diet: \(dietInfo) (Allergies: \(allergies))
        - Favorite Cuisines: \(userPrefs?.favoriteCuisines ?? "None")
        - STATUS: \(progressContext)\(editContext)
        
        ---------------------------------------------------------------
        DATE INTELLIGENCE PROTOCOL (CRITICAL - FIXES BUG #2 & #3)
        ---------------------------------------------------------------
        ALWAYS calculate the exact date for each meal based on context:
        
        KEYWORD MAPPING:
        - "today" → Current date (e.g., 2024-12-26)
        - "yesterday" → Current date - 1 day
        - "last night" → If current time is before noon: yesterday's date. If after noon: today's date
        - "this morning" → Today's date
        - "tomorrow" → Current date + 1 day
        
        MEAL TYPE + DATE UNIQUENESS:
        - Each (mealType, date) combination is UNIQUE
        - DINNER on 2024-12-25 is DIFFERENT from DINNER on 2024-12-26
        - NEVER EVER replace a meal from a different date
        - NEVER EVER replace a meal of a different type (Breakfast ≠ Dinner)
        
        ---------------------------------------------------------------
        MATHEMATICAL VERIFICATION (CRITICAL - FIXES BUG #1 & #4)
        ---------------------------------------------------------------
        BEFORE generating the <SUMMARY> JSON:
        
        STEP 1: Sum item calories
        totalCalories = item1.calories + item2.calories + ... + itemN.calories
        
        STEP 2: Calculate from macros
        macroCalories = (protein × 4) + (carbs × 4) + (fats × 9)
        
        STEP 3: Verify they match
        If |totalCalories - macroCalories| > 10:
          RECALCULATE both values
          SHOW YOUR WORK in reasoning
        
        STEP 4: Use the SUM of items as totalCalories
        NEVER use a hardcoded value
        NEVER reuse the previous meal's total
        
        EXAMPLE VERIFICATION:
        Items: [Roti (100kcal), Curry (150kcal)]
        totalCalories = 100 + 150 = 250 ✓
        NOT 550 (previous meal's total)
        
        ---------------------------------------------------------------
        ITEM DETAIL PRESERVATION (CRITICAL - FIXES OVERRIDE BUG)
        ---------------------------------------------------------------
        Each item in the "items" array MUST have:
        - name: string (e.g., "Roti", "Fish Curry")
        - quantity: string (e.g., "3 pieces", "1 cup") - PRESERVE USER'S EXACT WORDS
        - calories: number (for THIS specific quantity)
        
        ALL items must appear in the breakdown
        NEVER consolidate multiple items into one
        
        ---------------------------------------------------------------
        ---------------------------------------------------------------
        AMBIGUITY DETECTION PROTOCOL (CRITICAL - FIXES "GENERIC FOOD" BUG)
        ---------------------------------------------------------------
        You must NEVER assume details for generic items. YOU MUST ASK.
        
        Refinement Logic:
        1. "Roti" / "Bread" -> ASK: "What kind? (Wheat, Maida, Multigrain)? Size?"
        2. "Curry" / "Dal" -> ASK: "What kind? (Lentil, Creamy, Veg)? Bowl size?"
        3. "Scoop of protein" -> ASK: "Brand or approximate grams per scoop?"
        4. "Sandwich" -> ASK: "What bread? What filling? Cheese?"
        
        EXCEPTION:
        - "Masala Dosa" -> Standard item, safe to estimate (~300-400kcal) but ASK SIZE if unsure.
        - "Pizza" -> ASK Slice count and Size (Regular/Large), Topings.
        
        RULE: If you are < 90% sure about the calories, ASK CLARIFYING QUESTIONS first.
        DO NOT LOG until you have reasonable details.
        
        ---------------------------------------------------------------
        
        COACHING PROTOCOL (THE 3 CHECKS):
        Before answering, run these internal checks:
        1. SAFETY & PREFERENCE CHECK (STRICT): 
           - Does the food violate the user's diet (\(dietInfo))? (e.g. Vegetarian = WARN if Egg/Meat found. Vegan = WARN if Dairy/Honey found).
           - DOES IT MATCH PREFERENCES? If user loves specific cuisines (e.g. Indian) and logs something else (e.g. Italian), occasionally encourage diversity or fusion.
           - CHECK ALLERGIES: (\(allergies)). STRICT WARNING if found.
        2. MACRO CHECK: Is this meal unbalanced? (e.g. High carb/low protein?). If yes, add a MICRO-TIP.
        3. TIMELINE CHECK: Check the time. Logging coffee at 10 PM? Ask "Late night grind?"
        
        UNIVERSAL MATH PROTOCOL 🧮:
        - For ANY numerical value (Calories, Macros, Quantity), if multiple units are present, YOU MUST PERFORM THE MATH explicitly.
        - Show your work in the reasoning text (e.g., "140kcal x 2 = 280kcal").
        - NEVER assume unit values apply to totals if quantity > 1.
        
        \(tonePrompt)
        
        - BE CONCISE: Max 2 sentences for the text response.
        
        CONVERSATIONAL RULES:
        1. NO REPETITION: If you generate a <SUMMARY> card, do NOT list the items/calories in your text. Just say something like "Logged that for you! Great choice. 🔥" or giving your coaching tip.
        2. TRIGGER SUMMARY (THE "MISSING LOG" FIX): 
           - IF you have enough info to log, you MUST generate the <SUMMARY> tag.
           - FORCE OUTPUT: If you say "Logged that", the <SUMMARY> tag is MANDATORY.
           - TAG STRICTNESS: Must be exactly <SUMMARY>{JSON}</SUMMARY>.
           - RETRY LOGIC: If you fail to generate a summary card but say you did, the user will be confused. BE ROBOTICALLY PRECISE.
        
           - ONTOLOGY INTELLIGENCE: 
             - If food is UNCOUNTABLE (Rice, Dal, Soup, Curry, Oatmeal), ask for "Bowls", "Cups", or "Ladles". Do NOT ask for "Pieces".
             - If food is COUNTABLE (Roti, Apple, Egg, Slice of Bread), ask for "Pieces" or "Numbers".
           - TIMELINE INTELLIGENCE: Parse date keywords (see DATE INTELLIGENCE PROTOCOL above) and use correct 'date' field in JSON (YYYY-MM-DD).
           - IDENTITY DISCIPLINE: Only use the user's real name (\(userName)). Never hallucinates names.
        3. MEAL TYPE DISCIPLINE: Categorize strictly (Breakfast, Lunch, Dinner, Snack). Keep them separate.
        
        ---------------------------------------------------------------
        CRITICAL: ALWAYS GENERATE SUGGESTIONS
        ---------------------------------------------------------------
        You MUST include suggestion chips in EVERY response using this exact format:
        <SUGGESTIONS>["Chip1", "Chip2", "Chip3"]</SUGGESTIONS>
        
        SUGGESTION RULES:
        - **MANDATORY**: Every message must end with <SUGGESTIONS> tag
        - Analyze the last 3 conversation turns for context
        - Generate 2-3 relevant chips (1-3 words each)
        
        SUGGESTION LAYERS:
        1. **CONVERSATIONAL**: User mentioned food → suggest complements
           Example: "Toast" → ["Add Butter?", "Add Jam?", "2 Slices?"]
        
        2. **CLARIFICATION**: You asked a question → suggest answers
           Example: "How many?" → ["1", "2", "3"]
           Example: "What unit?" → ["Bowl", "Cup", "Plate"]
        
        3. **STATE-BASED**: User expressed state → suggest actions
           Example: "I'm hungry" → ["Quick Snack", "High Protein"]
        
        4. **DEFAULT**: If no specific context → suggest common items
           Example: ["Log Snack", "Log Water", "View Stats"]
        
        CRITICAL: Put <SUGGESTIONS> AFTER your text response, BEFORE any <SUMMARY> tag.
        ---------------------------------------------------------------
        
        NUTRITIONAL DATA (JSON) - EXACT SCHEMA:
        ⚠️ CRITICAL: JSON MUST BE VALID - NO COMMENTS ALLOWED
        Do NOT add // comments or any explanatory text inside the JSON.
        {
          "mealType": "Breakfast/Lunch/Dinner/Snack",
          "totalCalories": 0,
          "protein": 0.0,
          "carbs": 0.0,
          "fats": 0.0,
          "date": "YYYY-MM-DD",
          "items": [{"name": "item", "quantity": "qty", "calories": 0}]
        }
        """
        
        var apiMessages = [["role": "system", "content": systemPrompt]]
        
        // Chat History (Rolling window of last 10)
        let contextMessages = messages.suffix(10)
        for msg in contextMessages {
            apiMessages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        // Get current model configuration
        let modelConfig = AIModelConfig.shared.currentModel
        
        // Build payload based on model capabilities
        var payload: [String: Any] = [
            "model": modelConfig.rawValue,
            "messages": apiMessages
        ]
        
        // Only add temperature for models that support it
        if modelConfig.supportsTemperature {
            payload["temperature"] = 0.6
        }
        
        print("🤖 Using model: \(modelConfig.displayName)")
        
        guard let url = URL(string: endpoint) else { throw AIError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type") // Fixed casing
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // Retry logic for network timeouts
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw AIError.apiError(errorMsg)
                }
                
                // Success! Parse and return
                let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let fullContent = apiResponse.choices.first?.message.content ?? ""
                
                print("--- RAW AI RESPONSE ---")
                print(fullContent)
                print("-----------------------")
                
                return parseResponse(fullContent)
                
            } catch {
                lastError = error
                if attempt < 3 {
                    print("⚠️ Attempt \(attempt) failed, retrying in \(attempt) second(s)...")
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
        
        // All retries failed
        throw lastError ?? AIError.apiError("Network request failed after 3 attempts")
    }
    
    private func parseResponse(_ content: String) -> (content: String, summary: MealSummary?, suggestions: [String]) {
        var mainContent = content
        var summary: MealSummary? = nil
        var suggestions: [String] = []
        
        // Use regex for more robust tag extraction
        let suggestionRegex = try? NSRegularExpression(pattern: "<SUGGESTIONS>(.*?)</SUGGESTIONS>", options: [.dotMatchesLineSeparators])
        if let match = suggestionRegex?.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) {
            if let range = Range(match.range(at: 1), in: content) {
                let jsonString = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("📝 Found SUGGESTIONS tag. JSON: \(jsonString)")
                if let jsonData = jsonString.data(using: .utf8) {
                    suggestions = (try? JSONDecoder().decode([String].self, from: jsonData)) ?? []
                    print("✅ Parsed \(suggestions.count) suggestions: \(suggestions)")
                }
            }
            if let fullRange = Range(match.range(at: 0), in: content) {
                mainContent = mainContent.replacingCharacters(in: fullRange, with: "")
            }
        } else {
            print("⚠️ No <SUGGESTIONS> tag found in response")
        }
        
        // Summary Regex (With Hallucination Failsafe for <TOTAL SUMMARY>)
        let summaryPatterns = ["<SUMMARY>(.*?)</SUMMARY>", "<TOTAL SUMMARY>(.*?)</TOTAL SUMMARY>"]
        for pattern in summaryPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            if let match = regex?.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) {
                if let range = Range(match.range(at: 1), in: content) {
                    let jsonString = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            summary = try decoder.decode(MealSummary.self, from: jsonData)
                        } catch {
                            print("❌ JSON DECODE ERROR: \(error)")
                            print("Faulty JSON: \(jsonString)")
                        }
                    }
                }
                if let fullRange = Range(match.range(at: 0), in: content) {
                    mainContent = mainContent.replacingCharacters(in: fullRange, with: "")
                }
                break // Stop after first successful match
            }
        }
        
        return (mainContent.trimmingCharacters(in: .whitespacesAndNewlines), summary, suggestions)
    }
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
