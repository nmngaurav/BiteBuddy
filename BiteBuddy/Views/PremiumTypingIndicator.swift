import SwiftUI

/// Premium Typing Indicator with staggered bouncing dots
struct PremiumTypingIndicator: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0...2, id: \.self) { index in
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .opacity(animate ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
