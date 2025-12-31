//
//  DemoTapLogger.swift
//  Gym Flex Italia
//
//  Debug utility to catch dead buttons in demo mode
//

import Foundation

/// Logs button taps in demo mode to help identify "dead" buttons
/// Use: DemoTapLogger.log("ScreenName.ButtonName") at the start of every button action
enum DemoTapLogger {
    
    /// Logs a tap event if demo mode is enabled
    /// - Parameter name: A descriptive name for the button (e.g., "Profile.EditAvatar")
    static func log(_ name: String) {
        guard FeatureFlags.shared.isDemoMode else { return }
        
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("🔘 TAP [\(timestamp)]: \(name)")
    }
    
    /// Logs a tap with additional context
    /// - Parameters:
    ///   - name: Button identifier
    ///   - context: Additional context (e.g., item ID, state info)
    static func log(_ name: String, context: String) {
        guard FeatureFlags.shared.isDemoMode else { return }
        
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("🔘 TAP [\(timestamp)]: \(name) | \(context)")
    }
    
    /// Logs an action that resulted in no-op (for tracking dead buttons)
    /// - Parameter name: Button identifier
    static func logNoOp(_ name: String) {
        guard FeatureFlags.shared.isDemoMode else { return }
        
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("⚠️ NO-OP [\(timestamp)]: \(name) - Button has no implemented action!")
    }
}
