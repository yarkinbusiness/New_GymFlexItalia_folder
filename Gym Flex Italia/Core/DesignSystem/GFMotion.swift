//
//  GFMotion.swift
//  Gym Flex Italia
//
//  Design System: Animation presets
//

import SwiftUI

/// Design System animation presets
enum GFMotion {
    
    /// Gentle spring for subtle interactions (button press, toggle)
    static let gentle = Animation.spring(response: 0.35, dampingFraction: 0.85)
    
    /// Confirm spring for success states
    static let confirm = Animation.spring(response: 0.45, dampingFraction: 0.78)
    
    /// Smooth easing for continuous/live updates
    static let live = Animation.easeInOut(duration: 0.8)
    
    /// Quick snap for instant feedback
    static let snap = Animation.spring(response: 0.25, dampingFraction: 0.9)
    
    /// Standard duration for transitions
    static let standardDuration: Double = 0.3
}
