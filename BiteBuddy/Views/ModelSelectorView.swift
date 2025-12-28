import SwiftUI

struct ModelSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedModel: AIModel = AIModelConfig.shared.currentModel
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose the AI model for your nutrition coach")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Available Models") {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Button {
                            selectedModel = model
                            AIModelConfig.shared.setModel(model)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(model.displayName)
                                            .font(.headline)
                                        
                                        if model.requiresTier5 {
                                            Text("Tier 5")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .foregroundColor(.orange)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        Label(model.estimatedSpeed, systemImage: "bolt.fill")
                                            .font(.caption2)
                                            .foregroundColor(Theme.Colors.primary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedModel == model {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section {
                    Text("ℹ️ **Tier 5 models** require over $1,000 in OpenAI API spending. If you get connection errors, switch to GPT-4o.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("AI Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
