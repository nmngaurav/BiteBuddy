import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showHistory = false
    @State private var showPersonaSelector = false
    @State private var showWaterTracker = false
    @State private var showSettings = false
    
    // Fetch water intake for today
    @Query private var todayLogs: [DailyLog]
    @Query private var userPrefs: [UserPreferences]
    
    private var todayWater: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return todayLogs.first(where: { $0.date == today })?.waterIntake ?? 0
    }
    
    var body: some View {
        ZStack {
            // Premium Dark Background
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Settings Button (Left)
                    Button(action: { showSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    
                    Text("BiteBuddy")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Water Tracker Button
                    Button(action: { showWaterTracker = true }) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.secondary.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(Theme.Colors.secondary.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "drop.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(Theme.Colors.secondary)
                        }
                    }
                    
                    // History Button
                    Button(action: { showHistory = true }) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "calendar")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                    }
                    
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
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(Theme.Colors.backgroundPrimary)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.Colors.backgroundSecondary), alignment: .bottom)
                
                // Messages Area (with Premium Empty State)
                ScrollViewReader { proxy in
                    ScrollView {
                        if viewModel.messages.isEmpty {
                            // PREMIUM EMPTY STATE
                            ZStack {
                                // Subtle Dot Grid Pattern
                                GeometryReader { geometry in
                                    Canvas { context, size in
                                        let dotSpacing: CGFloat = 30
                                        let dotSize: CGFloat = 2
                                        
                                        for x in stride(from: 0, to: size.width, by: dotSpacing) {
                                            for y in stride(from: 0, to: size.height, by: dotSpacing) {
                                                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                                                context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.03)))
                                            }
                                        }
                                    }
                                }
                                
                                VStack(spacing: 40) {
                                    Spacer()
                                    
                                    // Minimalist Avatar & Greeting
                                    VStack(spacing: 20) {
                                        ZStack {
                                            Circle()
                                                .fill(Theme.Colors.primary.opacity(0.1))
                                                .frame(width: 70, height: 70)
                                            
                                            Image(systemName: viewModel.currentPersona.iconName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                                .foregroundColor(Theme.Colors.primary)
                                        }
                                        
                                        VStack(spacing: 8) {
                                            Text(greetingForTimeOfDay())
                                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.Colors.textPrimary)
                                            
                                            Text("I'm \(viewModel.currentPersona.displayName), your AI nutrition coach")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(Theme.Colors.textTertiary)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    
                                    // Floating Example Prompts
                                    VStack(spacing: 12) {
                                        Text("Try saying...")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textTertiary.opacity(0.7))
                                            .textCase(.uppercase)
                                            .tracking(1)
                                        
                                        VStack(spacing: 10) {
                                            FloatingPromptButton(text: "I had a cup of coffee ☕️") {
                                                viewModel.sendMessage("I had a cup of coffee")
                                            }
                                            FloatingPromptButton(text: "Log my breakfast 🌅") {
                                                viewModel.sendMessage("Log my breakfast")
                                            }
                                            FloatingPromptButton(text: "What's my progress? 📊") {
                                                viewModel.sendMessage("What's my progress?")
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                    
                                    Spacer()
                                    Spacer()
                                }
                            }
                        } else {
                            // MESSAGES LIST
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message, onHistoryAction: {
                                        showHistory = true
                                        hapticFeedback()
                                    })
                                    .id(message.id)
                                    .transition(message.isUser ? .userBubble : .chatBubble)
                                }
                                
                                if viewModel.isThinking {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Theme.Colors.backgroundSecondary)
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: viewModel.currentPersona.iconName)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundColor(Theme.Colors.primary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(viewModel.currentPersona.displayName)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Theme.Colors.textTertiary)
                                            
                                            PremiumTypingIndicator()
                                                .foregroundColor(Theme.Colors.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 25)
                                    .transition(.opacity)
                                }
                                
                                Color.clear.frame(height: 1).id("BOTTOM")
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo("BOTTOM", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isThinking) { _, isThinking in
                        if isThinking {
                            withAnimation {
                                proxy.scrollTo("BOTTOM", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Suggestions
                if !viewModel.suggestions.isEmpty && !viewModel.isThinking {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    viewModel.sendMessage(suggestion)
                                    hapticFeedback()
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.Colors.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Theme.Colors.primary.opacity(0.1))
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 10)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Compact Input Area
                CompactInputView(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    onSend: {
                        viewModel.sendMessage(viewModel.inputText)
                    }
                )
            }
            .blur(radius: viewModel.isLoading ? 10 : 0)
            
            // Celebration Overlay
            if viewModel.showCelebration {
                ParticleView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(100)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Theme.Colors.primary)
            }
        }
        .background(
            LinearGradient(
                colors: [Theme.Colors.backgroundPrimary, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            CalendarView()
        }
        .sheet(isPresented: $showWaterTracker) {
            WaterTrackerView(
                currentIntake: Binding(
                    get: { todayWater },
                    set: { newValue in
                        updateWater(newValue)
                    }
                ),
                goal: userPrefs.first?.dailyWaterGoal ?? 2500
            )
            .presentationDetents([.height(550)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPersonaSelector) {
            PersonaSelectionVerticalView(selectedPersona: Binding(
                get: { viewModel.currentPersona.rawValue },
                set: { newValue in
                    if let persona = BuddyPersona(rawValue: newValue) {
                        viewModel.updatePersona(persona)
                    }
                }
            ))
            .presentationDetents([.height(450)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showOnboarding) {
            OnboardingView(showOnboarding: $viewModel.showOnboarding)
                .onDisappear {
                    viewModel.fetchMessages()
                    NotificationManager.shared.requestPermission()
                }
        }
        .onChange(of: viewModel.showCelebration) { oldValue, newValue in
            if newValue {
                BiteEffects.successVibe()
                // Auto-hide celebration after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        viewModel.showCelebration = false
                    }
                }
            }
        }
        .onAppear {
            viewModel.setContext(modelContext)
            NotificationManager.shared.requestPermission()
        }
    }
    
    private func updateWater(_ newValue: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        if let existingLog = todayLogs.first(where: { $0.date == today }) {
            existingLog.waterIntake = newValue
        } else {
            let newLog = DailyLog(date: today, waterIntake: newValue)
            modelContext.insert(newLog)
        }
        try? modelContext.save()
    }
    
    
    // Helper: Time-based greeting
    private func greetingForTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning! ☀️"
        case 12..<17: return "Good Afternoon! 🌤️"
        case 17..<22: return "Good Evening! 🌙"
        default: return "Hey there! 🌟"
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// Floating Prompt Button Component
struct FloatingPromptButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            BiteEffects.selectionVibe()
        }) {
            HStack {
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Theme.Colors.backgroundSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primary.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

// Quick Action Button Component
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Theme.Colors.backgroundSecondary)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 1))
        }
    }
}
