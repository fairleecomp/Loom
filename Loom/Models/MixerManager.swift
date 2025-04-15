import Foundation
import AVFoundation

/// Represents a manager that handles multiple mixer tracks.
class MixerManager {
    static let shared = MixerManager()
    private init() {
        // Initialize 8 mixer track slots (nil means empty)
        tracks = Array(repeating: nil, count: 8)
    }
    
    // An array that holds an AVAudioPlayer for each track.
    var tracks: [AVAudioPlayer?]
    
    /// Assigns a new recording to the first available track.
    /// If all tracks are occupied, you could choose to override one or present an error.
    func assignRecording(url: URL) {
        // Attempt to create an audio player from the recorded file.
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            print("Error: Could not create player for URL: \(url)")
            return
        }
        // Set the player to loop indefinitely.
        player.numberOfLoops = -1
        player.prepareToPlay()
        player.play()
        
        // Find the first available (nil) track.
        for i in 0..<tracks.count {
            if tracks[i] == nil {
                tracks[i] = player
                print("Assigned recording to mixer track \(i + 1)")
                return
            }
        }
        
        print("No available mixer tracks. Consider freeing up one track first.")
    }
    
    /// Optional: Clear a specific mixer track.
    func clearTrack(at index: Int) {
        if index >= 0 && index < tracks.count {
            tracks[index]?.stop()
            tracks[index] = nil
            print("Cleared track \(index + 1)")
        }
    }
}
