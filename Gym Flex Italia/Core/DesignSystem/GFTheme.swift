//
//  GFTheme.swift
//  Gym Flex Italia
//
//  Design System: Theme environment container
//

import SwiftUI

/// Design System theme container
struct GFTheme {
    /// Color palette
    let colors: GFColors
    
    /// Creates a theme for the current color scheme
    static func forScheme(_ scheme: ColorScheme) -> GFTheme {
        GFTheme(colors: GFColors.from(colorScheme: scheme))
    }
}

// MARK: - Environment Key

private struct GFThemeKey: EnvironmentKey {
    static let defaultValue = GFTheme.forScheme(.light)
}

extension EnvironmentValues {
    /// Current GFTheme based on color scheme
    var gfTheme: GFTheme {
        get { self[GFThemeKey.self] }
        set { self[GFThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects the GFTheme based on current color scheme
    func withGFTheme() -> some View {
        modifier(GFThemeModifier())
    }
}

/// Modifier that injects the correct theme based on color scheme
private struct GFThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.gfTheme, GFTheme.forScheme(colorScheme))
    }
}
