//
//  GFMotion.swift
//  Gym Flex Italia
//
//  Design System: Animation presets
//

import SwiftUI
import UIKit

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
    
    // MARK: - Navigation Motion
    
    /// Navigation animation constants (single source of truth)
    enum NavigationMotion {
        /// Response time - how quickly the animation starts (lower = faster)
        static let response: Double = 0.30
        /// Damping - bounciness (lower = more bounce, 1.0 = no bounce)
        static let dampingFraction: Double = 0.76
        /// Blend duration - smoothness of spring start
        static let blendDuration: Double = 0.10
        /// Horizontal offset for micro-shift effect (points)
        static let microShiftOffset: CGFloat = 18
    }
    
    /// Perceptible but tasteful navigation animation for page-to-page transitions.
    /// Mimics Apple's system apps with subtle micro-bounce and felt horizontal travel.
    /// - Response: 0.30s (fast, responsive)
    /// - Damping: 0.76 (noticeable bounce)
    /// - Blend: 0.10s (quick spring start)
    ///
    /// This creates motion that is clearly perceptible but not flashy or theatrical.
    static let navigation = Animation.interactiveSpring(
        response: NavigationMotion.response,
        dampingFraction: NavigationMotion.dampingFraction,
        blendDuration: NavigationMotion.blendDuration
    )
    
    /// Returns the navigation animation only if Reduce Motion is disabled.
    /// When Reduce Motion is enabled, returns nil for instant transitions.
    ///
    /// Usage: `withAnimation(GFMotion.navigationIfAllowed) { ... }`
    static var navigationIfAllowed: Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : navigation
    }
}
