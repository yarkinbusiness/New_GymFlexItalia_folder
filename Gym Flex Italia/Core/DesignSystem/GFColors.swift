//
//  GFColors.swift
//  Gym Flex Italia
//
//  Design System: Color palette that adapts to light/dark mode
//

import SwiftUI

/// Design System color palette with layered surface system
struct GFColors {
    /// Primary accent color (use sparingly for key actions)
    let primary: Color
    
    /// Root app background (deepest layer)
    let surface0: Color
    
    /// Section background (intermediate layer)
    let surface1: Color
    
    /// Card/container surface (top layer - most prominent)
    let surface: Color
    
    /// Secondary surface (buttons, chips, interactive elements)
    let surface2: Color
    
    /// Elevated surface (for emphasis)
    let surfaceElevated: Color
    
    /// Primary text color (high emphasis)
    let textPrimary: Color
    
    /// Secondary text color (medium emphasis)
    let textSecondary: Color
    
    /// Tertiary text color (low emphasis, meta info)
    let textTertiary: Color
    
    /// Success state color
    let success: Color
    
    /// Warning state color
    let warning: Color
    
    /// Danger state color
    let danger: Color
    
    /// Subtle border color
    let border: Color
    
    // MARK: - Legacy alias
    
    /// Alias for surface0 (backwards compatibility)
    var background: Color { surface0 }
    
    // MARK: - Factory
    
    /// Creates a color palette for the given color scheme
    /// - Parameters:
    ///   - colorScheme: Current light/dark mode
    ///   - accent: App's primary accent color
    /// - Returns: Configured color palette
    static func from(colorScheme: ColorScheme, accent: Color = AppColors.brand) -> GFColors {
        switch colorScheme {
        case .dark:
            return GFColors(
                primary: accent,
                // Layered dark surfaces (subtle gradation)
                surface0: Color(hue: 0.67, saturation: 0.08, brightness: 0.08), // Deepest - near black with blue tint
                surface1: Color(hue: 0.67, saturation: 0.06, brightness: 0.12), // Section backgrounds
                surface: Color(hue: 0.67, saturation: 0.05, brightness: 0.16),  // Cards
                surface2: Color(hue: 0.67, saturation: 0.04, brightness: 0.20), // Buttons/chips
                surfaceElevated: Color(hue: 0.67, saturation: 0.04, brightness: 0.22), // Emphasized
                textPrimary: Color.white.opacity(0.95),
                textSecondary: Color.white.opacity(0.65),
                textTertiary: Color.white.opacity(0.40),
                success: Color(hue: 0.38, saturation: 0.70, brightness: 0.70),
                warning: Color(hue: 0.10, saturation: 0.75, brightness: 0.90),
                danger: Color(hue: 0.0, saturation: 0.70, brightness: 0.80),
                border: Color.white.opacity(0.08)
            )
        case .light:
            return GFColors(
                primary: accent,
                // Layered light surfaces (warm and inviting)
                surface0: Color(hue: 0.58, saturation: 0.02, brightness: 0.96), // Deepest - off-white
                surface1: Color(hue: 0.58, saturation: 0.01, brightness: 0.98), // Section backgrounds
                surface: Color.white,                                            // Cards - pure white
                surface2: Color(hue: 0.58, saturation: 0.02, brightness: 0.94), // Buttons/chips
                surfaceElevated: Color.white,                                    // Emphasized
                textPrimary: Color.black.opacity(0.90),
                textSecondary: Color.black.opacity(0.55),
                textTertiary: Color.black.opacity(0.35),
                success: Color(hue: 0.38, saturation: 0.65, brightness: 0.55),
                warning: Color(hue: 0.10, saturation: 0.80, brightness: 0.85),
                danger: Color(hue: 0.0, saturation: 0.65, brightness: 0.65),
                border: Color.black.opacity(0.06)
            )
        @unknown default:
            return from(colorScheme: .light, accent: accent)
        }
    }
}
