import SwiftUI

/// Water drop particle for burst animation
struct WaterDropParticle: View {
    let index: Int
    let totalParticles: Int
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.secondary,
                        Theme.Colors.secondary.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
            .offset(offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                let angle = (2 * .pi / Double(totalParticles)) * Double(index)
                let distance = CGFloat.random(in: 40...80)
                
                withAnimation(
                    .easeOut(duration: 1.2)
                    .delay(Double.random(in: 0...0.1))
                ) {
                    offset = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance + 20 // Gravity effect
                    )
                    scale = 0.3
                }
                
                withAnimation(
                    .easeIn(duration: 0.4)
                    .delay(0.8)
                ) {
                    opacity = 0.0
                }
            }
    }
}

/// Particle burst container
struct WaterDropBurst: View {
    @Binding var isShowing: Bool
    let particleCount: Int = 10
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                WaterDropParticle(index: index, totalParticles: particleCount)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                isShowing = false
            }
        }
    }
}
