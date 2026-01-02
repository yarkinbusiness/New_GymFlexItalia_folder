//
//  SettingsStore.swift
//  Gym Flex Italia
//
//  ObservableObject that manages app settings with UserDefaults persistence
//

import Foundation
import Combine
import SwiftUI

/// Manages app settings with automatic persistence to UserDefaults
@MainActor
final class SettingsStore: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current app settings (persisted automatically on change)
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaultsKey = "gymflex_app_settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    init() {
        // Load settings from UserDefaults or use defaults
        self.settings = Self.loadSettings() ?? .defaults
    }
    
    // MARK: - Public Methods
    
    /// Resets all settings to their default values
    func resetToDefaults() {
        settings = .defaults
    }
    
    /// Exports current settings as a JSON string (for debugging)
    func exportDebugString() -> String {
        do {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "Error encoding settings: \(error.localizedDescription)"
        }
    }
    
    /// Prints current settings to console (for debugging)
    func printDebugSettings() {
        #if DEBUG
        print("📋 Current Settings:")
        print(exportDebugString())
        #endif
    }
    
    // MARK: - Appearance Helpers
    
    /// Returns the ColorScheme for SwiftUI based on current settings
    /// Returns nil for "system" mode (follows device setting)
    var preferredColorScheme: ColorScheme? {
        switch settings.appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// Updates the appearance mode and syncs with AppearanceManager
    func setAppearanceMode(_ mode: AppearanceMode, appearanceManager: AppearanceManager? = nil) {
        settings.appearanceMode = mode
        
        // Sync with AppearanceManager if provided
        if let manager = appearanceManager {
            switch mode {
            case .system:
                // For system mode, we'll set based on current system appearance
                // The actual system tracking would need more work; for now default to dark
                manager.setColorScheme(.dark)
            case .light:
                manager.setColorScheme(.light)
            case .dark:
                manager.setColorScheme(.dark)
            }
        }
    }
    
    // MARK: - Appearance Display Helpers
    
    /// Display name for current appearance mode
    var appearanceDisplayName: String {
        switch settings.appearanceMode {
        case .dark:
            return "Dark Mode"
        case .light:
            return "Light Mode"
        case .system:
            return "System"
        }
    }
    
    /// Icon name for current appearance mode
    var appearanceIconName: String {
        switch settings.appearanceMode {
        case .dark:
            return "moon.fill"
        case .light:
            return "sun.max.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
    
    /// Toggles between light and dark mode
    /// If system mode, switches to dark first for deterministic behavior
    func toggleLightDark() {
        switch settings.appearanceMode {
        case .system:
            // From system, go to dark mode
            settings.appearanceMode = .dark
        case .dark:
            // From dark, go to light
            settings.appearanceMode = .light
        case .light:
            // From light, go to dark
            settings.appearanceMode = .dark
        }
        #if DEBUG
        print("🎨 Appearance toggled to: \(settings.appearanceMode.rawValue)")
        #endif
    }
    
    // MARK: - Private Methods
    
    private static func loadSettings() -> AppSettings? {
        guard let data = UserDefaults.standard.data(forKey: "gymflex_app_settings") else {
            #if DEBUG
            print("⚙️ No saved settings found, using defaults")
            #endif
            return nil
        }
        
        do {
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            #if DEBUG
            print("⚙️ Loaded settings from UserDefaults")
            #endif
            return settings
        } catch {
            #if DEBUG
            print("⚠️ Failed to decode settings: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
    
    private func saveSettings() {
        do {
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            #if DEBUG
            print("💾 Settings saved to UserDefaults")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to save settings: \(error.localizedDescription)")
            #endif
        }
    }
}
