import SwiftUI
import UIKit

// MARK: - BiteEffects Helper
struct BiteEffects {
    
    // MARK: - Haptics
    static func successVibe() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Follow up with a light impact for "texture"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    static func selectionVibe() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    static func impactVibe(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Transitions
extension AnyTransition {
    static var chatBubble: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8, anchor: .bottomLeading)
                .combined(with: .opacity)
                .combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
    }
    
    static var userBubble: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8, anchor: .bottomTrailing)
                .combined(with: .opacity)
                .combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
    }
}

// MARK: - Particle Views
struct ParticleView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(particle.emoji)
                    .font(.system(size: particle.size))
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .rotationEffect(particle.rotation)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            emitParticles()
        }
    }
    
    func emitParticles() {
        // Create 15-20 particles
        for _ in 0..<20 {
            let emoji = ["🥗", "🔥", "🥑", "🥕", "🍗", "✨"].randomElement()!
            let particle = Particle(
                emoji: emoji,
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height - 100, // Start from bottom
                size: CGFloat.random(in: 20...40),
                rotation: .degrees(Double.random(in: -30...30)),
                opacity: 1
            )
            particles.append(particle)
        }
        
        // Animate them
        for index in particles.indices {
            withAnimation(.easeOut(duration: Double.random(in: 1.0...1.5))) {
                particles[index].x += CGFloat.random(in: -150...150)
                particles[index].y -= CGFloat.random(in: 200...400) // Move UP
                particles[index].rotation += .degrees(Double.random(in: -90...90))
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let emoji: String
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var rotation: Angle
    var opacity: Double
}

// MARK: - Typing Indicator
struct WaveTypingIndicator: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                let indexPhase = phase + (CGFloat(index) * 0.5)
                let sinValue = sin(indexPhase)
                let yOffset: CGFloat = -4 * sinValue
                let opacityValue = 0.5 + (0.5 * sinValue)
                
                Circle()
                    .fill(Theme.Colors.textSecondary)
                    .frame(width: 8, height: 8)
                    .offset(y: yOffset)
                    .opacity(opacityValue)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
