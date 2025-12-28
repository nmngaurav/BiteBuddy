import Foundation

class OpenAIService: AIAssistant {
    private let apiKey = "YOUR_API_KEY_HERE"
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // API key is now hardcoded above
        if self.apiKey.isEmpty {
            print("⚠️ WARNING: API key is empty")
        }
    }
    
    func getResponse(for messages: [Message], userPrefs: UserPreferences?, dailyLog: DailyLog? = nil) async throws -> (content: String, summary: MealSummary?, suggestions: [String], waterAmount: Int?) {
        
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
        
        ---------------------------------------------------------------
        🚨 CRITICAL: SUGGESTIONS FIRST DIRECTIVE 🚨
        ---------------------------------------------------------------
        1. THOUGHT PROCESS: Decide what 3 chips are most helpful.
        2. EXPLICIT OUTPUT: You MUST output the <SUGGESTIONS> tag BEFORE your text response.
        
        FORMAT:
        <SUGGESTIONS>["Chip1", "Chip2", "Chip3"]</SUGGESTIONS>
        [Your text response here]
        
        🧠 INTELLIGENT CHIP LOGIC (THE "ANSWERABILITY" RULE):
        IF you ask a question, the chips MUST be VALID ANSWERS.
        
        ❌ BAD (Generic/Lazy):
        AI: "How much water?" -> ["Log Meal", "View Stats"] (USER CANNOT CLICK THESE TO ANSWER)
        
        ✅ GOOD (Context-Aware):
        AI: "How much water?" -> ["1 Glass", "500ml", "1 Liter"]
        AI: "Was it a small or large apple?" -> ["Small", "Medium", "Large"]
        AI: "I've logged that. Anything else?" -> ["Add Water", "Log Snack", "All Done"]
        
        ⚠️ CRITICAL RULES:
        1. NEVER output "Log Meal" if you are generating a <SUMMARY> tag in the SAME response
        2. If you just logged a meal → Suggest: ["Add Water", "Log Snack", "Check Stats"]
        3. If asking for details → Chips MUST be answers
        4. NEVER output generic chips if waiting for specific details

        - Confirming Log? -> ["Log Meal", "View Stats", "Check Goal"]
        ---------------------------------------------------------------
        
        TODAY IS: \(Date().formatted(date: .long, time: .standard))
        CURRENT TIME: \(Date().formatted(date: .omitted, time: .shortened))
        
        USER PROFILE:
        - Name: \(userName.isEmpty ? "Not provided" : userName) (If name is provided, use it naturally. If not, simply don't use a name - no placeholders like \"User\" or \"Buddy\".)
        - Goal: \(goalType) (Target: \(dailyGoal) kcal)
        - Diet: \(dietInfo) (Allergies: \(allergies))
        - Favorite Cuisines: \(userPrefs?.favoriteCuisines ?? "None")
        - STATUS: \(progressContext)\(editContext)
        
        ---------------------------------------------------------------
        📱 APP CAPABILITIES (YOU HAVE ACCESS TO THESE):
        ---------------------------------------------------------------
        1. WATER TRACKER: If user mentions "hydration" or "water", you can log it (<WATER_LOG>) or tell them to check the Water Tab.
        2. CALENDAR/HISTORY: You know the user's past logs (see 'Recent Logs' context). Reference them ("You had a heavy lunch, so...")
        3. GOAL SETTINGS: You know their target (\(dailyGoal) kcal). Remind them if they are close.
        4. ANALYSIS: You can analyze macros and provide tips.
        
        🧠 INTELLIGENCE & TONE UPGRADE:
        - Be an EMPATHIC PARTNER, not a robot. Use emojis naturally.
        - CELEBRATE wins ("Great job hitting protein!").
        - BE PROACTIVE: If it's dinner time and they have 800kcal left, suggest a hearty meal.
        - BE PRECISE: Don't guess. If you need details, ask nicely.
        ---------------------------------------------------------------
        
        ---------------------------------------------------------------
        DATE INTELLIGENCE PROTOCOL (CRITICAL - FIXES DATE BUG)
        ---------------------------------------------------------------
        🚨 MANDATORY: EVERY <SUMMARY> JSON MUST include an explicit "date" field 🚨
        
        DEFAULT RULE (CRITICAL):
        - IF user does NOT mention "yesterday", "last night", "tomorrow", or any temporal keyword
        - THEN use TODAY'S DATE: \(Date().formatted(date: .abbreviated, time: .omitted))
        - NEVER assume "yesterday" by default!
        
        KEYWORD MAPPING:
        - NO temporal keyword (e.g., "I had coffee", "Log 2 dosas") → TODAY (\(Date().formatted(date: .abbreviated, time: .omitted)))
        - "today", "just now", "this morning" → TODAY
        - "yesterday", "last night" (before noon) → YESTERDAY (Current date - 1 day)
        - "last night" (after noon) → TODAY
        - "tomorrow" → TOMORROW (Current date + 1 day)
        - "on Monday", "last week" → Calculate exact date
        
        MEAL TYPE + DATE UNIQUENESS:
        - Each (mealType, date) combination is UNIQUE
        - DINNER on 2024-12-25 is DIFFERENT from DINNER on 2024-12-26
        - NEVER EVER replace a meal from a different date
        - NEVER EVER replace a meal of a different type (Breakfast ≠ Dinner)
        
        OUTPUT FORMAT REQUIREMENT:
        Your <SUMMARY> JSON MUST always include:
        {
          "date": "YYYY-MM-DD",  // ← MANDATORY! Use exact calculated date
          ...
        }
        
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
        WATER_LOGGING PROTOCOL (NEW - PHASE 15)
        ---------------------------------------------------------------
        IF user says they drank water (keywords: "water", "drank", "hydration", "sip"):
        OUTPUT TAG: <WATER_LOG>amount_ml</WATER_LOG>
        
        EXAMPLES:
        - "I drank a glass of water" → <WATER_LOG>250</WATER_LOG>
        - "Had 2 bottles" → <WATER_LOG>1000</WATER_LOG> (assume 500ml per bottle)
        - "Just had water" → <WATER_LOG>250</WATER_LOG> (default to 1 glass)
        
        TEXT RESPONSE: "Hydration check! 💧 +[amount]ml added."
        
        DO NOT generate <SUMMARY> for water logs, only <WATER_LOG>.
        ---------------------------------------------------------------
        
        COACHING PROTOCOL (THE 3 CHECKS):
        Before answering, run these internal checks:
        1. ⚠️ DIETARY SAFETY CHECK (BLOCKING - PHASE 15 UPGRADE): 
           - IF user's diet is Vegetarian AND food contains (chicken, fish, meat, beef, pork):
             → STOP IMMEDIATELY. OUTPUT WARNING: "⚠️ Wait! [Food] contains meat. You're set to Vegetarian. Should I still log this?"
           - IF user's diet is Vegan AND food contains (dairy, milk, cheese, egg, honey, butter):
             → STOP IMMEDIATELY. OUTPUT WARNING: "⚠️ Hold on! [Food] has [ingredient]. You're Vegan. Proceed anyway?"
           - CHECK ALLERGIES: (\(allergies)). If found → STOP & WARN.
           - This check is MANDATORY and takes precedence over logging.
           
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
        JSON STRICTNESS PROTOCOL (ULTRA-CRITICAL - PARSING REQUIREMENT)
        ---------------------------------------------------------------
        🚨 ABSOLUTE REQUIREMENT: JSON MUST BE VALID 🚨
        
        The system CANNOT parse JSON with:
        - Comments (// or /* */)
        - Trailing commas
        - Arithmetic expressions
        - Explanatory text
        
        ❌ INVALID JSON EXAMPLES (NEVER DO THIS):
        
        EXAMPLE 1 - ARITHMETIC (BREAKS PARSER):
        {
          "totalCalories": 208 + 140,  // ← INVALID! Parser sees "+" as syntax error
          "protein": 2.0 + 12.0        // ← INVALID! Must be pre-calculated number
        }
        
        EXAMPLE 2 - COMMENTS (BREAKS PARSER):
        {
          "totalCalories": 348,  // Beer + Omelette ← INVALID! Comments break JSON
          "protein": 14.0        // ← INVALID! No comments allowed
        }
        
        ✅ VALID JSON (ALWAYS DO THIS):
        {
          "mealType": "Dinner",
          "totalCalories": 348,
          "protein": 14.0,
          "carbs": 19.0,
          "fats": 10.0,
          "date": "2025-12-27",
          "items": [
            {"name": "Beer", "quantity": "1 pint", "calories": 208},
            {"name": "Omelette", "quantity": "2 eggs", "calories": 140}
          ],
          "healthScore": 5
        }
        
        MANDATORY PRE-RESPONSE CHECKLIST:
        Before sending response, verify:
        ☐ Step 1: Did I calculate totalCalories? (208 + 140 = 348) ✓
        ☐ Step 2: Did I calculate protein? (2.0 + 12.0 = 14.0) ✓
        ☐ Step 3: Did I calculate carbs? (17.0 + 2.0 = 19.0) ✓
        ☐ Step 4: Did I calculate fats? (0.0 + 10.0 = 10.0) ✓
        ☐ Step 5: Is my JSON free of ALL comments? ✓
        ☐ Step 6: Is my JSON free of ALL arithmetic? ✓
        
        IF ANY STEP FAILS → FIX IMMEDIATELY BEFORE SENDING
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
          "items": [{"name": "item", "quantity": "qty", "calories": 0}],
          "healthScore": 7
        }
        
        HEALTH SCORE PROTOCOL (NEW - GAMIFICATION):
        Every meal MUST include a "healthScore" (1-10 rating) based on these criteria:
        
        10-9 (Superfood Tier):
          - Whole foods, lean protein, abundant vegetables
          - Example: Grilled fish + quinoa + large salad
        
        8-7 (Vitality Boost):
          - Nutrient-dense, well-balanced
          - Example: Chicken breast + brown rice + broccoli
        
        6-5 (Solid Fuel):
          - Reasonable balance, standard meal
          - Example: Pasta with vegetables, sandwich
        
        4-3 (Indulgent):
          - Higher cal, lower nutrients (but that's okay!)
          - Example: Pizza, burger with fries
        
        2-1 (Pure Treat):
          - Very high cal, minimal nutrients
          - Example: Chocolate cake, ice cream sundae
        
        TONE: Health score is NOT judgmental - it's gamification!
        """
        
        var apiMessages = [["role": "system", "content": systemPrompt]]
        
        // Chat History (Rolling window of last 10)
        let contextMessages = messages.suffix(10)
        for msg in contextMessages {
            var content = msg.content
            
            // PHASE 18 FIX: INJECT REMINDER INTO USER MESSAGE
            // This overcomes "Context Amnesia" where the model forgets system prompt instructions
            // due to long history. We force the instruction into the immediate context.
            if msg.isUser && msg == contextMessages.last {
                content += "\n\n(Internal Note: You MUST start your response with the <SUGGESTIONS> tag. This is mandatory.)"
            }
            
            apiMessages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": content
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
    
    private func parseResponse(_ content: String) -> (content: String, summary: MealSummary?, suggestions: [String], waterAmount: Int?) {
        var mainContent = content
        var summary: MealSummary? = nil
        var suggestions: [String] = []
        var waterAmount: Int? = nil
        
        // WATER_LOG parsing
        let waterRegex = try? NSRegularExpression(pattern: "<WATER_LOG>(\\d+)</WATER_LOG>", options: [])
        if let match = waterRegex?.firstMatch(in: mainContent, options: [], range: NSRange(mainContent.startIndex..., in: mainContent)) {
            if let range = Range(match.range(at: 1), in: mainContent) {
                let amountString = String(mainContent[range])
                waterAmount = Int(amountString)
                print("💧 Found WATER_LOG tag: \(waterAmount ?? 0)ml")
            }
            // Remove the tag from content
            if let fullRange = Range(match.range(at: 0), in: mainContent) {
                mainContent.removeSubrange(fullRange)
            }
        }
        
        // Use regex for more robust tag extraction
        let suggestionRegex = try? NSRegularExpression(pattern: "<SUGGESTIONS>(.*?)</SUGGESTIONS>", options: [.dotMatchesLineSeparators])
        if let match = suggestionRegex?.firstMatch(in: mainContent, options: [], range: NSRange(mainContent.startIndex..., in: mainContent)) {
            if let range = Range(match.range(at: 1), in: mainContent) {
                let jsonString = String(mainContent[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("📝 Found SUGGESTIONS tag. JSON: \(jsonString)")
                if let jsonData = jsonString.data(using: .utf8) {
                    suggestions = (try? JSONDecoder().decode([String].self, from: jsonData)) ?? []
                    print("✅ Parsed \(suggestions.count) suggestions: \(suggestions)")
                }
            }
            // Remove the tag from content
            if let fullRange = Range(match.range(at: 0), in: mainContent) {
                mainContent.removeSubrange(fullRange)
            }
        } else {
            print("⚠️ No <SUGGESTIONS> tag found in response")
        }
        
        // Summary Regex (With Hallucination Failsafe for <TOTAL SUMMARY>)
        let summaryPatterns = ["<SUMMARY>(.*?)</SUMMARY>", "<TOTAL SUMMARY>(.*?)</TOTAL SUMMARY>"]
        for pattern in summaryPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            if let match = regex?.firstMatch(in: mainContent, options: [], range: NSRange(mainContent.startIndex..., in: mainContent)) {
                if let range = Range(match.range(at: 1), in: mainContent) {
                    let jsonString = String(mainContent[range]).trimmingCharacters(in: .whitespacesAndNewlines)
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
                // Remove the tag from content
                if let fullRange = Range(match.range(at: 0), in: mainContent) {
                    mainContent.removeSubrange(fullRange)
                }
                break // Stop after first successful match
            }
        }
        
        return (mainContent.trimmingCharacters(in: .whitespacesAndNewlines), summary, suggestions, waterAmount)
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
