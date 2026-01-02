//
//  Haptics.swift
//  Gym Flex Italia
//
//  Haptic feedback helper for success/warning events
//

import UIKit

/// Minimal haptic feedback helper
/// Only used for meaningful success events (booking, extend, top-up)
enum Haptics {
    
    // MARK: - Feedback Types
    
    /// Success haptic - use for confirmed actions only
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning haptic - use for attention-needed states
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error haptic - use for failed actions
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// Light impact - use for subtle confirmations
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Selection feedback - use for picker/toggle changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
