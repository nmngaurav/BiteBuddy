import Foundation

// MARK: - AI Model Configuration
enum AIModel: String, CaseIterable {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
    case o1Mini = "o1-mini"
    case o1 = "o1"
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o (Recommended)"
        case .gpt4oMini: return "GPT-4o Mini (Faster)"
        case .o1Mini: return "O1-Mini (Max Accuracy)"
        case .o1: return "O1 (Premium)"
        }
    }
    
    var description: String {
        switch self {
        case .gpt4o: 
            return "Best balance of speed, cost, and accuracy for nutrition tracking"
        case .gpt4oMini: 
            return "Faster and cheaper, good for simple conversations"
        case .o1Mini: 
            return "Maximum calculation accuracy, slower responses (Requires Tier 5)"
        case .o1: 
            return "Best accuracy, slowest, most expensive (Requires Tier 5)"
        }
    }
    
    var supportsTemperature: Bool {
        switch self {
        case .gpt4o, .gpt4oMini:
            return true
        case .o1Mini, .o1:
            return false // o1 models don't support temperature
        }
    }
    
    var requiresTier5: Bool {
        switch self {
        case .gpt4o, .gpt4oMini:
            return false
        case .o1Mini, .o1:
            return true
        }
    }
    
    var estimatedSpeed: String {
        switch self {
        case .gpt4o: return "⚡⚡⚡"
        case .gpt4oMini: return "⚡⚡⚡⚡"
        case .o1Mini: return "⚡"
        case .o1: return "⚡"
        }
    }
}

// MARK: - Model Configuration Manager
class AIModelConfig {
    static let shared = AIModelConfig()
    
    // Default model - change this to switch models globally
    private(set) var currentModel: AIModel = .gpt4o
    
    func setModel(_ model: AIModel) {
        currentModel = model
        UserDefaults.standard.set(model.rawValue, forKey: "selectedAIModel")
        print("🤖 Switched to model: \(model.displayName)")
    }
    
    func loadSavedModel() {
        if let savedModel = UserDefaults.standard.string(forKey: "selectedAIModel"),
           let model = AIModel(rawValue: savedModel) {
            currentModel = model
        }
    }
    
    init() {
        loadSavedModel()
    }
}
