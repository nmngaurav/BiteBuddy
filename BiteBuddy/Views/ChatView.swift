import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showHistory = false
    @State private var showPersonaSelector = false
    
    var body: some View {
        ZStack {
            // Premium Dark Background
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BiteBuddy")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("PRECISION LOGGING")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Theme.Colors.primary)
                            .kerning(3)
                    }
                    Spacer()
                    
                    // History Button (Custom Calendar Icon)
                    Button(action: { showHistory = true }) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(Theme.Colors.backgroundSecondary.opacity(0.5), lineWidth: 1)
                                )
                            
                            Image(systemName: "calendar")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                    }
                    .padding(.trailing, 12)
                    
                    // Persona Avatar Button
                    Button(action: { showPersonaSelector = true }) {
                        ZStack(alignment: .bottomTrailing) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.backgroundSecondary)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: viewModel.currentPersona.iconName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Theme.Colors.primary)
                            }
                            
                            // Edit Badge
                            Circle()
                                .fill(Theme.Colors.primary)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Theme.Colors.backgroundPrimary)
                                )
                                .overlay(Circle().stroke(Theme.Colors.backgroundPrimary, lineWidth: 2))
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(Theme.Colors.backgroundPrimary) // Seamless header
                .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.Colors.backgroundSecondary), alignment: .bottom)
                
                // Chat List
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, onHistoryAction: {
                                    showHistory = true
                                    hapticFeedback()
                                })
                                .id(message.id)
                            }
                            
                            if viewModel.isThinking {
                                TypingIndicator()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 30)
                    }
                    .onChange(of: viewModel.messages.count) {
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Floating Interaction Area
                VStack(spacing: 0) {
                    // Suggestions
                    if !viewModel.suggestions.isEmpty && !viewModel.isThinking {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        viewModel.sendMessage(suggestion)
                                        hapticFeedback()
                                    }) {
                                        Text(suggestion)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Theme.Colors.backgroundSecondary)
                                            .foregroundColor(Theme.Colors.primary)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                        }
                    }
                    
                    // Input Bar
                    HStack(spacing: 12) {
                        TextField("", text: $viewModel.inputText, prompt: Text("Describe intake...").foregroundColor(Theme.Colors.textTertiary))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Theme.Colors.backgroundInput)
                            .cornerRadius(27)
                        
                        Button(action: {
                            viewModel.sendMessage()
                            hapticFeedback()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.primary)
                                    .frame(width: 54, height: 54)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Theme.Colors.backgroundPrimary)
                            }
                        }
                        .disabled(viewModel.inputText.isEmpty)
                        .opacity(viewModel.inputText.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                .background(Theme.Colors.backgroundPrimary)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.Colors.backgroundSecondary), alignment: .top)
            }
        }
        .fullScreenCover(isPresented: $showHistory) {
            CalendarView()
        }
        .sheet(isPresented: $showPersonaSelector) {
            PersonaSelectionVerticalView(selectedPersona: Binding(
                get: { viewModel.currentPersona },
                set: { viewModel.updatePersona($0) }
            ))
            .presentationDetents([.fraction(0.85)]) // Tall vertical sheet
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showOnboarding) {
            OnboardingView(showOnboarding: $viewModel.showOnboarding)
                .onDisappear {
                    viewModel.fetchMessages()
                }
        }
        .onAppear {
            viewModel.setContext(modelContext)
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
