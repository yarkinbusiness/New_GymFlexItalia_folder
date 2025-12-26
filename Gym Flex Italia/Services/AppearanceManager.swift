//
//  AppearanceManager.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/22/25.
//

import SwiftUI
import Combine

/// Manages the app's appearance (light/dark mode)
@MainActor
final class AppearanceManager: ObservableObject {
    
    static let shared = AppearanceManager()
    
    @Published var colorScheme: ColorScheme {
        didSet {
            savePreference()
        }
    }
    
    private let userDefaultsKey = "app_color_scheme"
    
    private init() {
        // Load saved preference or default to dark
        if let savedScheme = UserDefaults.standard.string(forKey: userDefaultsKey) {
            self.colorScheme = savedScheme == "light" ? .light : .dark
        } else {
            self.colorScheme = .dark
        }
    }
    
    /// Toggle between light and dark mode
    func toggleAppearance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            colorScheme = colorScheme == .dark ? .light : .dark
        }
    }
    
    /// Set specific color scheme
    func setColorScheme(_ scheme: ColorScheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            colorScheme = scheme
        }
    }
    
    /// Save preference to UserDefaults
    private func savePreference() {
        let schemeString = colorScheme == .dark ? "dark" : "light"
        UserDefaults.standard.set(schemeString, forKey: userDefaultsKey)
    }
    
    /// Get display name for current scheme
    var displayName: String {
        colorScheme == .dark ? "Dark Mode" : "Light Mode"
    }
    
    /// Get icon for current scheme
    var iconName: String {
        colorScheme == .dark ? "moon.fill" : "sun.max.fill"
    }
}
