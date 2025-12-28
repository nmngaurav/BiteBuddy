import SwiftUI

/// A premium, fluid audio visualizer that simulates organic voice energy.
/// Uses multiple rounded bars with randomized but smooth height animations.
struct FluidAudioVisualizer: View {
    let isRecording: Bool
    
    // Configuration for the bars
    private let barCount = 20
    private let barSpacing: CGFloat = 4
    private let minHeight: CGFloat = 10
    private let maxHeight: CGFloat = 80
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                FluidBar(
                    index: index,
                    totalBars: barCount,
                    isRecording: isRecording,
                    minHeight: minHeight,
                    maxHeight: maxHeight
                )
            }
        }
        .frame(height: maxHeight)
    }
}

private struct FluidBar: View {
    let index: Int
    let totalBars: Int
    let isRecording: Bool
    let minHeight: CGFloat
    let maxHeight: CGFloat
    
    @State private var height: CGFloat = 10
    @State private var animationOffset: Double = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.primary,
                        Theme.Colors.secondary.opacity(0.8)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 6, height: height)
            .opacity(isRecording ? 1.0 : 0.3)
            .onChange(of: isRecording) { _, recording in
                if recording {
                    startAnimating()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        height = minHeight
                    }
                }
            }
            .onAppear {
                if isRecording {
                    startAnimating()
                }
            }
    }
    
    private func startAnimating() {
        // Calculate a unique delay based on index to create a "wave" effect
        // or purely random for "voice" effect.
        // For voice, slightly random + sine wave mix looks best.
        
        let delay = Double.random(in: 0...0.5)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isRecording else {
                timer.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                // Simulate organic voice amplitude
                // Center bars (near index = totalBars/2) should generally be taller
                let centerBias = 1.0 - abs(Double(index) - Double(totalBars)/2) / (Double(totalBars)/2)
                let randomVar = Double.random(in: 0.2...1.0)
                let targetHeight = minHeight + (maxHeight - minHeight) * CGFloat(centerBias * randomVar)
                
                self.height = targetHeight
            }
        }
    }
}
