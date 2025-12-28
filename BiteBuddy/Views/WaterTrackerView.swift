import SwiftUI
import SwiftData
import AVFoundation

struct WaterTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var currentIntake: Int
    let goal: Int
    
    // Animation state
    @State private var waveOffset = Angle(degrees: 0)
    @State private var showSplash = false
    @State private var showParticleBurst = false
    @State private var showCelebration = false
    @State private var previousProgress: Double = 0.0
    @State private var milestoneReached: Int? = nil
    
    private let soundManager = WaterSoundManager.shared
    private let reminderScheduler = WaterReminderScheduler.shared
    
    var progress: Double {
        return min(Double(currentIntake) / Double(goal), 1.0)
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(10)
                            .background(Theme.Colors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("Hydration")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        // Streak Display
                        if WaterStreakManager.shared.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 14))
                                Text("\(WaterStreakManager.shared.currentStreak) Day Streak")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.Colors.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    // Placeholder for balance
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)
                
                // Main Tracker (Ring with Wave)
                ZStack {
                    // Background Ring
                    Circle()
                        .stroke(Theme.Colors.backgroundSecondary, lineWidth: 20)
                        .frame(width: 250, height: 250)
                    
                    // Wave Masked Circle
                    Circle()
                        .frame(width: 250, height: 250)
                        .foregroundColor(Theme.Colors.backgroundSecondary.opacity(0.3))
                        .overlay(
                            Wave(offset: waveOffset, percent: progress)
                                .fill(Theme.Colors.secondary) // Cyan
                                .clipShape(Circle())
                        )
                        .overlay(
                             Circle()
                                .stroke(Theme.Colors.secondary, lineWidth: 4)
                                .scaleEffect(showSplash ? 1.1 : 1.0)
                                .opacity(showSplash ? 0 : 1)
                        )
                    
                    // Text Info
                    VStack(spacing: 5) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        
                        Text("\(currentIntake) / \(goal) ml")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                        
                        // Over-goal celebration
                        if progress > 1.0 {
                            Text("Hydration Hero! 🏆")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.Colors.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.white.opacity(0.2)))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .shadow(color: Theme.Colors.secondary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Quick Add Buttons
                HStack(spacing: 20) {
                    WaterAddButton(amount: 250, icon: "drop.fill", action: { addWater(250) })
                    WaterAddButton(amount: 500, icon: "water.waves", action: { addWater(500) })
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // Particle Burst Overlay
            if showParticleBurst {
                WaterDropBurst(isShowing: $showParticleBurst)
                    .position(x: UIScreen.main.bounds.width / 2, y: 250)
            }
            
            // Goal Celebration Overlay
            if showCelebration {
                WaterCelebration(isShowing: $showCelebration)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = Angle(degrees: 360)
            }
        }
    }
    
    private func addWater(_ amount: Int) {
        let oldProgress = progress
        
        // Bouncy spring animation for premium feel
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65, blendDuration: 0.3)) {
            currentIntake += amount
            showSplash = true
        }
        
        // Show particle burst
        showParticleBurst = true
        
        // Reset splash animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
        }
        
        // Milestone detection
        let newProgress = progress
        checkMilestone(oldProgress: oldProgress, newProgress: newProgress)
        
        // Premium sound effect - procedural filling
        soundManager.playFillingSound()
        
        // Update reminder schedule (reset timer)
        reminderScheduler.handleWaterLogged()
        
        // Haptic feedback with intensity
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }
    
    private func checkMilestone(oldProgress: Double, newProgress: Double) {
        let milestones = [0.25, 0.50, 0.75, 1.0]
        
        for milestone in milestones {
            if oldProgress < milestone && newProgress >= milestone {
                if milestone == 1.0 {
                    // Goal complete celebration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCelebration = true
                        soundManager.play(.goalComplete)
                        
                        // Check and update streak
                        WaterStreakManager.shared.checkGoalReached(intake: currentIntake, goal: goal)
                    }
                } else {
                    // Milestone pulse (visual feedback)
                    milestoneReached = Int(milestone * 100)
                    
                    // Milestone sound
                    soundManager.play(.milestone)
                    
                    // Stronger haptic for milestones
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                break
            }
        }
    }
}

// MARK: - Components

struct WaterAddButton: View {
    let amount: Int
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("+\(amount)ml")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Theme.Colors.secondary)
            .cornerRadius(20)
            .shadow(color: Theme.Colors.secondary.opacity(0.4), radius: 10, y: 5)
        }
    }
}

struct Wave: Shape {
    var offset: Angle
    var percent: Double
    
    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lowestWave = 0.02
        let highestWave = 1.00
        
        let newPercent = lowestWave + (highestWave - lowestWave) * percent
        let waveHeight = 0.05 * rect.height
        let yOffset = CGFloat(1 - newPercent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360)
        
        path.move(to: CGPoint(x: 0, y: yOffset + waveHeight * CGFloat(sin(offset.radians))))
        
        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 5) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            path.addLine(to: CGPoint(x: x, y: yOffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
