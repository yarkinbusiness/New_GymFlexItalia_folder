//
//  BuildConfig.swift
//  Gym Flex Italia
//
//  Centralized build configuration flags.
//

import Foundation

/// Centralized build configuration
/// Use this for environment-aware logic throughout the app.
struct BuildConfig {
    
    // MARK: - Build Type
    
    /// Whether this is a DEBUG build
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Whether this is a RELEASE build
    static var isRelease: Bool {
        !isDebug
    }
    
    // MARK: - Environment
    
    /// Current environment name for display
    static var environmentName: String {
        #if DEBUG
        return "Debug Demo"
        #else
        return "Production"
        #endif
    }
    
    /// Short environment label
    static var environmentLabel: String {
        #if DEBUG
        return "DEV"
        #else
        return "PROD"
        #endif
    }
    
    // MARK: - Feature Flags
    
    /// Whether to show debug tools in UI
    static var showDebugTools: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Whether to use mock services
    static var useMockServices: Bool {
        // Always use mocks until backend is ready
        return true
    }
    
    /// Whether verbose logging is enabled
    static var verboseLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
