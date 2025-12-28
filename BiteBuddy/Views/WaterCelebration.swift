import SwiftUI

/// Full-screen celebration for reaching 100% water goal
struct WaterCelebration: View {
    @Binding var isShowing: Bool
    @State private var confettiOpacity: Double = 0.0
    @State private var badgeScale: CGFloat = 0.0
    @State private var textOffset: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 30) {
                // Trophy Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                    
                    Image(systemName: "trophy.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                }
                .scaleEffect(badgeScale)
                
                // Celebration Text
                VStack(spacing: 10) {
                    Text("Goal Achieved!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("You stayed hydrated today! 💧")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .offset(y: textOffset)
                .opacity(textOffset == 0 ? 1 : 0)
            }
            
            // Confetti Overlay
            ConfettiView()
                .opacity(confettiOpacity)
                .allowsHitTesting(false)
        }
        .onAppear {
            // Badge animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                badgeScale = 1.0
            }
            
            // Text animation
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOffset = 0
            }
            
            // Confetti
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                confettiOpacity = 1.0
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
            
            // Haptic celebration
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            confettiOpacity = 0
            badgeScale = 0
            textOffset = -50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

/// Simple confetti effect
struct ConfettiView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<40, id: \.self) { index in
                    ConfettiPiece(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        delay: Double.random(in: 0...0.5)
                    )
                }
            }
        }
    }
}

struct ConfettiPiece: View {
    let x: CGFloat
    let delay: Double
    @State private var y: CGFloat = -20
    @State private var rotation: Double = 0
    
    let colors: [Color] = [.cyan, .blue, .white, .yellow, .orange]
    
    var body: some View {
        Rectangle()
            .fill(colors.randomElement() ?? .cyan)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .position(x: x, y: y)
            .onAppear {
                withAnimation(
                    .linear(duration: 2.5)
                    .delay(delay)
                ) {
                    y = UIScreen.main.bounds.height + 50
                    rotation = Double.random(in: 0...720)
                }
            }
    }
}
