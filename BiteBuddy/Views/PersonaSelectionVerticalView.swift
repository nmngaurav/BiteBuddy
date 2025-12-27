import SwiftUI

struct PersonaSelectionVerticalView: View {
    @Binding var selectedPersona: String
    @Environment(\.dismiss) var dismiss
    
    // Animation State
    @State private var appearingIndex: Int = -1
    
    var body: some View {
        ZStack {
            // Theme Background
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Choose Your Coach")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                .padding(25)
                .background(Theme.Colors.backgroundPrimary)
                
                // Vertical List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(Array(BuddyPersona.allCases.enumerated()), id: \.element) { index, persona in
                            PersonaVerticalCard(
                                persona: persona,
                                isSelected: selectedPersona == persona.rawValue,
                                action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedPersona = persona.rawValue
                                    }
                                }
                            )
                            .offset(y: appearingIndex >= index ? 0 : 50)
                            .opacity(appearingIndex >= index ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appearingIndex)
                        }
                    }
                    .padding(25)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            appearingIndex = BuddyPersona.allCases.count
        }
    }
}

struct PersonaVerticalCard: View {
    let persona: BuddyPersona
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Left: Avatar Image (Large)
                ZStack {
                    if isSelected {
                        // Premium Glow Behind
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.3))
                            .blur(radius: 20)
                            .frame(width: 90, height: 90)
                    }
                    
                    Image(systemName: persona.iconName) // Placeholder, ideally use real Image asset if available
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(width: 100)
                .background(Theme.Colors.backgroundPrimary.opacity(0.3))
                
                // Right: Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(persona.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    
                    Text(persona.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 20)
                .padding(.trailing, 20)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.trailing, 20)
                }
            }
            .background(isSelected ? Theme.Colors.backgroundSecondary : Theme.Colors.backgroundSecondary.opacity(0.5))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Theme.Colors.primary.opacity(0.1) : .clear, radius: 10, x: 0, y: 5)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
