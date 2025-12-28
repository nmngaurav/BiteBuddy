import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @Environment(\.modelContext) private var modelContext
    
    // User inputs
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var dailyGoal = 2000
    @State private var goalType = "Maintain"
    @State private var dietType = "None"
    @State private var allergies = ""
    @State private var selectedPersona = BuddyPersona.biteBuddy.rawValue
    
    let goalTypes = ["Weight Loss", "Maintain", "Muscle Gain"]
    let dietTypes = ["None", "Vegetarian", "Vegan", "Keto"]
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Capsule()
                            .fill(index <= currentStep ? Theme.Colors.primary : Theme.Colors.backgroundSecondary)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep(onNext: { withAnimation { currentStep += 1 } })
                        .tag(0)
                        .transition(.slide)
                    
                    NameStep(name: $userName, onNext: { withAnimation { currentStep += 1 } })
                        .tag(1)
                        .transition(.slide)
                    
                    GoalStep(name: userName, goal: $dailyGoal, goalType: $goalType, goalTypes: goalTypes, onNext: { withAnimation { currentStep += 1 } })
                        .tag(2)
                        .transition(.slide)
                    
                    DietStep(name: userName, dietType: $dietType, allergies: $allergies, dietTypes: dietTypes, onNext: { withAnimation { currentStep += 1 } })
                        .tag(3)
                        .transition(.slide)
                    
                    PersonaStep(selectedPersona: $selectedPersona, onFinish: saveAndFinish)
                        .tag(4)
                        .transition(.slide)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
    }
    
    private func saveAndFinish() {
        let prefs = UserPreferences(
            name: userName,
            dailyGoal: dailyGoal,
            dietType: dietType,
            allergies: allergies,
            favoriteCuisines: "",
            hasCompletedOnboarding: true,
            goalType: goalType,
            activityLevel: "Active",
            selectedPersona: selectedPersona
        )
        modelContext.insert(prefs)
        try? modelContext.save()
        
        withAnimation {
            showOnboarding = false
        }
    }
}

// MARK: - Steps

struct WelcomeStep: View {
    var onNext: () -> Void
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.primary)
            }
            .onAppear { animateIcon = true }
            
            VStack(spacing: 12) {
                Text("BiteBuddy")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("Your AI Nutrition Coach")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            PrimaryButton(title: "Let's Get Started", action: onNext)
        }
        .padding(25)
    }
}

struct NameStep: View {
    @Binding var name: String
    var onNext: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("What's your name?")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("We'll personalize your experience")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            TextField("", text: $name, prompt: Text("Your Name").foregroundColor(Theme.Colors.textTertiary))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(20)
                .background(Theme.Colors.backgroundSecondary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(name.count >= 2 ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
                .onAppear { isFocused = true }
            
            Spacer()
            
            PrimaryButton(title: "Continue", action: onNext, disabled: name.count < 2)
        }
        .padding(25)
    }
}

struct GoalStep: View {
    var name: String
    @Binding var goal: Int
    @Binding var goalType: String
    let goalTypes: [String]
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Nice to meet you, \(name)!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("What's your primary goal?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // Goal type selector
            VStack(spacing: 12) {
                ForEach(goalTypes, id: \.self) { type in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { goalType = type }
                    }) {
                        HStack {
                            Text(type)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(goalType == type ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            Spacer()
                            if goalType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.primary)
                                    .transition(.scale)
                            }
                        }
                        .padding(18)
                        .background(goalType == type ? Theme.Colors.backgroundSecondary : Theme.Colors.backgroundSecondary.opacity(0.5))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(goalType == type ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                        )
                        .scaleEffect(goalType == type ? 1.02 : 1.0)
                    }
                }
            }
            
            Spacer()
            
            PrimaryButton(title: "Continue", action: onNext)
        }
        .padding(25)
    }
}

struct DietStep: View {
    var name: String
    @Binding var dietType: String
    @Binding var allergies: String
    let dietTypes: [String]
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Any preferences?")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("We'll keep you safe, \(name)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // Diet type selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dietTypes, id: \.self) { type in
                        Button(action: { withAnimation { dietType = type } }) {
                            Text(type)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(dietType == type ? Theme.Colors.primary : Theme.Colors.backgroundSecondary)
                                .foregroundColor(dietType == type ? Theme.Colors.backgroundPrimary : Theme.Colors.textSecondary)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            
            TextField("", text: $allergies, prompt: Text("Allergies (e.g. Peanuts)").foregroundColor(Theme.Colors.textTertiary))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(18)
                .background(Theme.Colors.backgroundSecondary)
                .cornerRadius(16)
            
            Spacer()
            
            PrimaryButton(title: "Finish Setup", action: onNext)
        }
        .padding(25)
    }
}

struct PersonaStep: View {
    @Binding var selectedPersona: String
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Squad")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.top, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(BuddyPersona.allCases, id: \.self) { persona in
                        PersonaVerticalCard(
                            persona: persona,
                            isSelected: selectedPersona == persona.rawValue,
                            action: { withAnimation { selectedPersona = persona.rawValue } }
                        )
                    }
                }
                .padding(.horizontal, 25)
            }
            
            PrimaryButton(title: "Start My Journey", action: onFinish)
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Helpers

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(disabled ? Theme.Colors.textTertiary.opacity(0.3) : Theme.Colors.primary)
                .cornerRadius(28)
                .shadow(color: Theme.Colors.primary.opacity(disabled ? 0 : 0.4), radius: 10, x: 0, y: 5)
                .scaleEffect(disabled ? 0.98 : 1.0)
                .animation(.spring(), value: disabled)
        }
        .disabled(disabled)
    }
}
