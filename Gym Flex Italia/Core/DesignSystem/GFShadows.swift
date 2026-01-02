//
//  GFShadows.swift
//  Gym Flex Italia
//
//  Design System: Shadow presets for premium depth
//

import SwiftUI

/// Design System shadow presets - soft and premium
enum GFShadows {
    
    /// Card shadow preset - soft and layered
    /// - Returns: Tuple with radius, y offset, and opacity
    static func cardShadow() -> (radius: CGFloat, y: CGFloat, opacity: Double) {
        (radius: 12, y: 4, opacity: 0.08)
    }
    
    /// Subtle shadow for smaller elements
    static func subtleShadow() -> (radius: CGFloat, y: CGFloat, opacity: Double) {
        (radius: 6, y: 2, opacity: 0.05)
    }
    
    /// Elevated shadow for floating elements (modals, sheets)
    static func elevatedShadow() -> (radius: CGFloat, y: CGFloat, opacity: Double) {
        (radius: 20, y: 8, opacity: 0.12)
    }
    
    /// Premium shadow with ambient glow (for hero cards)
    static func premiumShadow() -> (radius: CGFloat, y: CGFloat, opacity: Double) {
        (radius: 16, y: 6, opacity: 0.10)
    }
}

// MARK: - View Extension

extension View {
    /// Apply card shadow - soft and layered
    func gfCardShadow() -> some View {
        let preset = GFShadows.cardShadow()
        return self
            // Ambient layer
            .shadow(
                color: Color.black.opacity(preset.opacity * 0.3),
                radius: preset.radius * 2,
                x: 0,
                y: 0
            )
            // Primary shadow
            .shadow(
                color: Color.black.opacity(preset.opacity),
                radius: preset.radius,
                x: 0,
                y: preset.y
            )
    }
    
    /// Apply subtle shadow
    func gfSubtleShadow() -> some View {
        let preset = GFShadows.subtleShadow()
        return self.shadow(
            color: Color.black.opacity(preset.opacity),
            radius: preset.radius,
            x: 0,
            y: preset.y
        )
    }
    
    /// Apply elevated shadow (for modals, sheets)
    func gfElevatedShadow() -> some View {
        let preset = GFShadows.elevatedShadow()
        return self
            // Ambient layer
            .shadow(
                color: Color.black.opacity(preset.opacity * 0.3),
                radius: preset.radius * 1.5,
                x: 0,
                y: 0
            )
            // Primary shadow
            .shadow(
                color: Color.black.opacity(preset.opacity),
                radius: preset.radius,
                x: 0,
                y: preset.y
            )
    }
    
    /// Apply premium shadow (for hero cards)
    func gfPremiumShadow() -> some View {
        let preset = GFShadows.premiumShadow()
        return self
            // Soft ambient
            .shadow(
                color: Color.black.opacity(preset.opacity * 0.4),
                radius: preset.radius * 2,
                x: 0,
                y: 2
            )
            // Main directional
            .shadow(
                color: Color.black.opacity(preset.opacity),
                radius: preset.radius,
                x: 0,
                y: preset.y
            )
    }
}
