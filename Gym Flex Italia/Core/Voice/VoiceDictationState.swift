//
//  VoiceDictationState.swift
//  Gym Flex Italia
//
//  Voice dictation state machine for chat composer.
//  Defines the possible states during voice input.
//

import Foundation

/// Represents the current state of voice dictation
enum VoiceDictationState: Equatable {
    /// No dictation active - normal input mode
    case idle
    
    /// Actively listening for voice input
    case listening
    
    /// Processing and committing the transcribed text
    case committing
    
    /// Dictation was cancelled by user
    case cancelled
}
