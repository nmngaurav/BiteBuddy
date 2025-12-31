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
        // Load custom pouring water sound
        if let player = loadSound(for: .drop, filename: "pouring-water") {
            player.volume = 0.6 // Comfortable volume for water sound
            audioPlayers[.drop] = player
        }
        
        // Attempt to load other custom sounds (optional)
        for soundType in WaterSoundType.allCases {
            if soundType != .drop { // Already loaded drop sound above
                if let player = loadSound(for: soundType, filename: soundType.filename) {
                    player.volume = 0.7
                    audioPlayers[soundType] = player
                }
            }
            
            // Populate system sound fallbacks
            switch soundType {
            case .drop:
                systemSounds[.drop] = 1306 // Water drop sound (fallback)
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
    /// NOW REPLACED: Just plays the custom pouring water sound once
    func playFillingSound() {
        guard isSoundEnabled else { return }
        play(.drop) // Play the custom pouring-water.wav
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
