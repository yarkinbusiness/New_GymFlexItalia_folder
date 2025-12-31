//
//  AppSettings.swift
//  Gym Flex Italia
//
//  Model for app-wide settings with persistence support
//

import Foundation

/// Represents the user's appearance preference
enum AppearanceMode: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// Measurement system preference
enum MeasurementSystem: String, Codable, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric: return "Metric (kg, cm)"
        case .imperial: return "Imperial (lb, in)"
        }
    }
}

/// App-wide settings model
/// Persisted to UserDefaults via SettingsStore
struct AppSettings: Codable, Equatable {
    
    // MARK: - Appearance
    
    /// User's preferred appearance mode (system/light/dark)
    var appearanceMode: AppearanceMode
    
    // MARK: - Notifications
    
    /// Whether push notifications are enabled (UI preference; actual permission is separate)
    var enablePushNotifications: Bool
    
    /// Whether workout reminders are enabled
    var enableWorkoutReminders: Bool
    
    // MARK: - Location
    
    /// Whether location features are enabled
    var enableLocationFeatures: Bool
    
    // MARK: - Haptics & Sound
    
    /// Whether haptic feedback is enabled
    var enableHaptics: Bool
    
    /// Whether sound effects are enabled
    var enableSoundEffects: Bool
    
    // MARK: - Privacy
    
    /// Whether user has opted into analytics
    var privacyAnalyticsOptIn: Bool
    
    // MARK: - Localization
    
    /// Preferred language ("system" follows device, or specific like "en", "it")
    var language: String
    
    /// Preferred measurement system
    var measurementSystem: MeasurementSystem
    
    // MARK: - Defaults
    
    /// Default settings for new users
    static var defaults: AppSettings {
        AppSettings(
            appearanceMode: .system,
            enablePushNotifications: true,
            enableWorkoutReminders: true,
            enableLocationFeatures: true,
            enableHaptics: true,
            enableSoundEffects: true,
            privacyAnalyticsOptIn: false,
            language: "system",
            measurementSystem: .metric
        )
    }
}
