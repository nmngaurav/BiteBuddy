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
            HStack(spacing: 16) {
                // Left: Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.primary.opacity(0.15) : Theme.Colors.backgroundPrimary.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: persona.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }
                
                // Right: Purpose-focused text
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.description)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.trailing, 8)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.Colors.backgroundPrimary)
                        )
                }
            }
            .padding(16)
            .background(isSelected ? Theme.Colors.backgroundSecondary : Theme.Colors.backgroundSecondary.opacity(0.5))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Theme.Colors.primary.opacity(0.2) : .clear, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
