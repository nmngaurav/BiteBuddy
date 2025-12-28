import SwiftUI

struct CompactInputView: View {
    @Binding var text: String
    var isLoading: Bool
    var onSend: () -> Void
    
    @State private var showVoiceInputSheet = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Text Input Field
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Tell me what you ate... 🥗")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    TextField("", text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .focused($isFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.Colors.backgroundSecondary.opacity(0.5))
                .cornerRadius(22)
                .disabled(isLoading)
                
                // Right Side: Mic or Send
                if isLoading {
                    ProgressView()
                        .tint(Theme.Colors.primary)
                        .frame(width: 44, height: 44)
                } else if !text.isEmpty {
                    // Send Button
                    Button(action: {
                        onSend()
                        BiteEffects.selectionVibe()
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.primary)
                            .clipShape(Circle())
                    }
                } else {
                    // Mic Button - Launch Voice Input Sheet
                    Button(action: {
                        showVoiceInputSheet = true
                        BiteEffects.impactVibe(style: .medium)
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.Colors.textTertiary.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.backgroundPrimary.opacity(0.95))
        }
        .sheet(isPresented: $showVoiceInputSheet) {
            VoiceInputSheet(isPresented: $showVoiceInputSheet) { confirmedText in
                text = confirmedText
                onSend()
            }
        }
    }
}
