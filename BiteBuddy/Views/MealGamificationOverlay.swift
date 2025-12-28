import SwiftUI
import Foundation

struct MealGamificationOverlay: View {
    @Binding var isShowing: Bool
    let healthScore: Int
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var particleBurst = false
    
    var body: some View {
        ZStack {
            // Full Screen Overlay
            Theme.Colors.backgroundPrimary.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Main Icon & Text
                VStack(spacing: 20) {
                    // Icon with Particle Burst
                    ZStack {
                        // Background Glow
                        Circle()
                            .fill(categoryColor.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                        
                        // Main Badge
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [categoryColor, categoryColor.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 150, height: 150)
                            
                            Text(categoryEmoji)
                                .font(.system(size: 70))
                        }
                        .scaleEffect(scale)
                        
                        // Particle Burst
                        if particleBurst {
                            ForEach(0..<12, id: \.self) { i in
                                Circle()
                                    .fill(categoryColor)
                                    .frame(width: 8, height: 8)
                                    .offset(particleOffset(index: i))
                                    .opacity(particleBurst ? 0 : 1)
                            }
                        }
                    }
                    
                    // Category Text
                    VStack(spacing: 8) {
                        Text(categoryTitle)
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(categorySubtitle)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private var categoryColor: Color {
        switch healthScore {
        case 8...10: return Color(hex: "10B981") // Emerald (Healthy)
        case 5...7: return Color(hex: "06B6D4")  // Cyan (Balanced)
        default: return Color(hex: "A855F7")     // Purple (Indulgent)
        }
    }
    
    private var categoryEmoji: String {
        switch healthScore {
        case 8...10: return "🌿"
        case 5...7: return "⛽"
        default: return "🍪"
        }
    }
    
    private var categoryTitle: String {
        switch healthScore {
        case 8...10: return "Vitality Boost!"
        case 5...7: return "Solid Fuel!"
        default: return "Tasty Treat!"
        }
    }
    
    private var categorySubtitle: String {
        switch healthScore {
        case 8...10: return "Supercharged nutrition"
        case 5...7: return "Balanced energy"
        default: return "Pure enjoyment"
        }
    }
    
    private func particleOffset(index: Int) -> CGSize {
        let angle = (Double(index) / 12.0) * 2 * Double.pi
        let radius: CGFloat = particleBurst ? 100 : 0
        return CGSize(
            width: CGFloat(Foundation.cos(angle)) * radius,
            height: CGFloat(Foundation.sin(angle)) * radius
        )
    }
    
    private func startAnimation() {
        // Icon pop-in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            scale = 1.1
            opacity = 1.0
        }
        
        // Settle
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
            scale = 1.0
        }
        
        // Particle burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.8)) {
                particleBurst = true
            }
        }
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowing = false
            }
        }
    }
}

#Preview {
    MealGamificationOverlay(isShowing: .constant(true), healthScore: 9)
}
