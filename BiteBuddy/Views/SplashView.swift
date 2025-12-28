import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showText = false
    @State private var shockwaveScale: CGFloat = 0.5
    @State private var shockwaveOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Deep Premium Background
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Living Logo Centerpiece
                ZStack {
                    // 1. Shockwave Ripple
                    Circle()
                        .stroke(Theme.Colors.secondary.opacity(0.3), lineWidth: 2)
                        .scaleEffect(shockwaveScale)
                        .opacity(shockwaveOpacity)
                    
                    // 2. Glow Background
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                    
                    // 3. Main Icon Container
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.brandGradient)
                            .frame(width: 120, height: 120)
                            .shadow(color: Theme.Colors.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        // Avocado/Leaf Symbol
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(30))
                    }
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                }
                
                // 4. Text Reveal
                if showText {
                    VStack(spacing: 8) {
                        Text("BiteBuddy")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        
                        Text("Nutrition Simplified")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .tracking(2)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Heartbeat / Living Logo Effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        // Shockwave Effect
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            shockwaveScale = 2.5
            shockwaveOpacity = 0.0
        }
        
        // Text Slide Up (Delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showText = true
            }
        }
    }
}

#Preview {
    SplashView()
}
