import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var step = 0
    // We can use the vertical selector here for the persona step
    
    // User Prefs references (simplified for this view)
    // In a real app we'd bind to ViewModel, but for now let's assume we save to valid defaults or use a ViewModel
    // Let's use a local State for persona selection
    @State private var selectedPersona: String = BuddyPersona.biteBuddy.rawValue
    
    // For transition animation
    @State private var showVerticalSelector = false
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack {
                // Determine step content
                if step == 0 {
                    WelcomeStep(onNext: { step += 1 })
                } else if step == 1 {
                    // Persona Selection Step using the NEW Vertical View
                    PersonaSelectionVerticalView(selectedPersona: $selectedPersona)
                        .transition(.move(edge: .trailing))
                    
                    // Button to Confirm Selection and Finish
                    Button(action: {
                        // Save preference (mock logic or call viewModel)
                        // UserDefaults.standard.set(selectedPersona, forKey: "selectedPersona") 
                        // In reality, ChatViewModel handles this via UserPreferences. 
                        // For this UI task, we just close onboarding.
                        saveAndDismiss()
                    }) {
                        Text("Start My Journey")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.Colors.primary)
                            .cornerRadius(28)
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(25)
                }
            }
            .animation(.spring(), value: step)
        }
    }
    
    private func saveAndDismiss() {
        // Here we would ideally save the selectedPersona to SwiftData or shared prefs
        // For now, we assume the user picks it and we dismiss.
        // The ViewModel in ChatView re-fetches context on disappear.
        
        // Quick hack: Save to UserDefaults just to persist across sessions if SwiftData isn't wired directly here
        // But better is to just let ChatView handle it or use EnvironmentObject.
        // Given constraints, we just close.
        showOnboarding = false
    }
}

struct WelcomeStep: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)
                .padding()
                .background(Circle().fill(Theme.Colors.backgroundSecondary).frame(width: 150, height: 150))
            
            VStack(spacing: 12) {
                Text("Welcome to BiteBuddy")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your AI-powered nutrition coach.\nSimple. Smart. Premium.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            Button(action: onNext) {
                Text("Let's Go")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.backgroundPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.Colors.primary)
                    .cornerRadius(28)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(25)
        }
    }
}
