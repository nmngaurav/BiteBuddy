import Foundation

protocol AIAssistant {
    func getResponse(for messages: [Message], userPrefs: UserPreferences?, dailyLog: DailyLog?) async throws -> (content: String, summary: MealSummary?, suggestions: [String], waterAmount: Int?)
}

enum AIError: Error {
    case invalidResponse
    case apiError(String)
}
