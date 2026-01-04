//
//  DictationAudioSession.swift
//  Gym Flex Italia
//
//  Dedicated audio session manager for voice dictation.
//  Handles activation/deactivation with proper cleanup.
//

import AVFAudio

/// Singleton manager for dictation audio session
/// Ensures reliable mic access and proper cleanup
@MainActor
final class DictationAudioSession {
    
    // MARK: - Singleton
    
    static let shared = DictationAudioSession()
    
    // MARK: - Properties
    
    private let session = AVAudioSession.sharedInstance()
    
    /// Whether the audio session is currently active
    private(set) var isActive: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Activates the audio session for dictation
    /// Uses .playAndRecord with spokenAudio mode for optimal speech recognition
    /// - Throws: AVAudioSession errors if activation fails
    func activate() throws {
        #if DEBUG
        print("🎙️ DictationAudioSession.activate() - Starting...")
        #endif
        
        // Configure for speech recognition:
        // - .playAndRecord: Ensures mic works reliably
        // - .spokenAudio: Optimized for voice input
        // - .duckOthers: Reduces other audio volume instead of stopping it
        // - .defaultToSpeaker: Output through speaker (not earpiece)
        // - .allowBluetooth: Support Bluetooth headsets
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.duckOthers, .defaultToSpeaker, .allowBluetooth]
        )
        
        try session.setActive(true, options: [])
        isActive = true
        
        #if DEBUG
        print("🎙️ DictationAudioSession.activate() - Success")
        #endif
    }
    
    /// Deactivates the audio session
    /// Notifies other apps so music can resume
    func deactivate() {
        guard isActive else {
            #if DEBUG
            print("🎙️ DictationAudioSession.deactivate() - Already inactive, skipping")
            #endif
            return
        }
        
        #if DEBUG
        print("🎙️ DictationAudioSession.deactivate() - Starting...")
        #endif
        
        do {
            // .notifyOthersOnDeactivation allows music apps to resume playback
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
            
            #if DEBUG
            print("🎙️ DictationAudioSession.deactivate() - Success")
            #endif
        } catch {
            // Log error but don't crash - deactivation failures are recoverable
            #if DEBUG
            print("🎙️ DictationAudioSession.deactivate() - Error:", error.localizedDescription)
            #endif
        }
        
        isActive = false
    }
}
