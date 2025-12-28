import SwiftUI

struct MessageBubble: View {
    let message: Message
    var onHistoryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                if !message.isUser {
                    Image(systemName: "sparkles")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundColor(Theme.Colors.primary) // Emerald Sparkles
                        .padding(8)
                        .background(Circle().fill(Theme.Colors.primary.opacity(0.1)))
                }
                
                if message.isUser { Spacer() }
                
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            message.isUser ? Theme.Colors.primary : Theme.Colors.backgroundSecondary
                        )
                        .foregroundColor(Theme.Colors.textPrimary)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(message.isUser ? Theme.Colors.primary : Theme.Colors.backgroundSecondary.opacity(0.5), lineWidth: 1)
                        )
                }
                
                if !message.isUser { Spacer() }
            }
            .padding(.horizontal)
            
            if let summaryData = message.summaryData, 
               let data = summaryData.data(using: .utf8),
               let summary = try? JSONDecoder().decode(MealSummary.self, from: data) {
                SummaryCard(summary: summary, onHistoryAction: onHistoryAction)
                    .padding(.horizontal)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 8, height: 8)
                    .offset(y: dotOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotOffset
                    )
            }
        }
        .onAppear { dotOffset = -6 }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.Colors.backgroundSecondary.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

struct SummaryCard: View {
    let summary: MealSummary
    var onHistoryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header: Precision Metric
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(summary.mealType.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Theme.Colors.secondary)
                            .kerning(2)
                    }
                    
                    Text("NUTRITIONAL METRIC")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .kerning(1.0)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(summary.totalCalories)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("KCAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Theme.Colors.primary)
                        .kerning(2)
                }
            }
            
            // Macros: Tactical Grid
            HStack(spacing: 15) {
                MacroMetric(label: "PROTEIN", value: summary.protein, unit: "G", color: Theme.Colors.secondary)
                MacroMetric(label: "CARBS", value: summary.carbs, unit: "G", color: Theme.Colors.secondary)
                MacroMetric(label: "FATS", value: summary.fats, unit: "G", color: Theme.Colors.secondary)
            }
            
            // Item Breakdown: Professional List
            VStack(alignment: .leading, spacing: 12) {
                Text("BREAKDOWN")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .kerning(2)
                
                ForEach(summary.items) { item in
                    HStack {
                        Text(item.name.uppercased())
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Theme.Colors.textPrimary) // Light text on dark card
                        Spacer()
                        Text("\(item.calories) KCAL")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.vertical, 10)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.Colors.backgroundPrimary), alignment: .bottom)
                }
            }
            
            // Footer Action: Precision Verification
            HStack {
                Spacer()
                Button(action: { onHistoryAction?() }) {
                    HStack(spacing: 4) {
                        Text("VIEW IN HISTORY")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Theme.Colors.secondary)
                    .kerning(1)
                    .padding(.top, 10)
                }
            }
        }
        .padding(25)
        .background(Theme.Colors.backgroundSecondary) // Dark card background
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10) // Deeper shadow for dark mode
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.Colors.textSecondary.opacity(0.2), lineWidth: 1)) // Subtle border
    }
}

struct MacroMetric: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.Colors.textTertiary)
                .kerning(1)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(unit)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
