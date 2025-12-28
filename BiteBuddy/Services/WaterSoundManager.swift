import Foundation
import AVFoundation

/// Manager for water tracker sound effects
class WaterSoundManager {
    static let shared = WaterSoundManager()
    
    private var audioPlayers: [WaterSoundType: AVAudioPlayer] = [:]
    private var systemSounds: [WaterSoundType: SystemSoundID] = [:]
    var isSoundEnabled: Bool = true
    
    enum WaterSoundType: CaseIterable {
        case drop
        case milestone
        case goalComplete
        
        var filename: String {
            switch self {
            case .drop: return "water_drop"
            case .milestone: return "milestone_chime"
            case .goalComplete: return "goal_complete"
            }
        }
    }
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    /// Preload all sound files into memory for zero-latency playback
    private func preloadSounds() {
        // Attempt to load custom sounds
        for soundType in WaterSoundType.allCases {
            if let player = loadSound(for: soundType, filename: soundType.filename) {
                player.volume = 0.7
                audioPlayers[soundType] = player
            }
            
            // Populate system sound fallbacks
            switch soundType {
            case .drop:
                systemSounds[.drop] = 1306 // Water drop sound
            case .milestone:
                systemSounds[.milestone] = 1103 // Milestone chime
            case .goalComplete:
                systemSounds[.goalComplete] = 1117 // Celebration sound
            }
        }
    }
    
    /// Play a water sound effect
    func play(_ soundType: WaterSoundType) {
        guard isSoundEnabled else { return }
        
        // Try AVAudioPlayer first for custom sounds
        if let player = audioPlayers[soundType] {
            player.currentTime = 0
            player.play()
            return
        }
        
        // Fallback to system sounds
        let soundId = systemSounds[soundType] ?? 1057
        AudioServicesPlaySystemSound(soundId)
    }
    
    /// Plays a procedural "filling" sound effect using pitch-shifted drops
    func playFillingSound() {
        guard isSoundEnabled else { return }
        
        // Create a sequence of drops with increasing pitch to simulate filling
        let baseDelay = 0.12
        
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay * Double(i)) {
                // Use system sound with slight variation
                AudioServicesPlaySystemSound(1057) // Tink sound
                
                // Optional: try to use custom player with rate adjustment
                if let dropPlayer = self.audioPlayers[.drop] {
                    dropPlayer.currentTime = 0
                    // Slightly increase pitch/rate for each subsequent drop
                    dropPlayer.enableRate = true
                    dropPlayer.rate = 1.0 + (Float(i) * 0.15)
                    dropPlayer.play()
                }
            }
        }
    }
    
    /// Play sound with delay
    func play(_ soundType: WaterSoundType, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.play(soundType)
        }
    }
    
    private func loadSound(for type: WaterSoundType, filename: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "wav") else {
            print("⚠️ Sound file not found: \(filename).wav - will use system sound")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("⚠️ Failed to load sound \(filename): \(error)")
            return nil
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error)")
        }
    }
    
    /// Toggle sound effects on/off
    func toggleSound() {
        isSoundEnabled.toggle()
    }
}
