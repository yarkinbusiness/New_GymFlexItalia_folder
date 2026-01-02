//
//  HapticGate.swift
//  Gym Flex Italia
//
//  Prevents double haptics and ensures single-fire per success event
//

import Foundation

/// Gate to prevent duplicate haptic triggers in quick succession
enum HapticGate {
    
    /// TTL for debouncing (seconds)
    private static let debounceInterval: TimeInterval = 2.0
    
    /// Tracks recently fired keys with timestamps
    private static var recentlyFired: [String: Date] = [:]
    
    /// Lock for thread safety
    private static let lock = NSLock()
    
    /// Fires the action only if the key hasn't been fired recently
    /// - Parameters:
    ///   - key: Unique identifier for this haptic event (e.g., "booking_success")
    ///   - action: The haptic action to perform
    static func fireOnce(key: String, action: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        
        // Clean up expired entries
        recentlyFired = recentlyFired.filter { now.timeIntervalSince($0.value) < debounceInterval }
        
        // Check if this key was recently fired
        if let lastFired = recentlyFired[key] {
            let elapsed = now.timeIntervalSince(lastFired)
            if elapsed < debounceInterval {
                // Skip - already fired recently
                #if DEBUG
                print("🔇 HapticGate: Skipping '\(key)' (fired \(String(format: "%.1f", elapsed))s ago)")
                #endif
                return
            }
        }
        
        // Record this fire
        recentlyFired[key] = now
        
        #if DEBUG
        print("🔔 HapticGate: Firing '\(key)'")
        #endif
        
        // Execute the action
        action()
    }
    
    /// Clears all gate history (useful for testing)
    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        recentlyFired.removeAll()
    }
}

// MARK: - Convenience Methods

extension HapticGate {
    
    /// Fires success haptic with built-in debouncing
    static func successOnce(key: String) {
        fireOnce(key: key) {
            Haptics.success()
        }
    }
    
    /// Fires warning haptic with built-in debouncing
    static func warningOnce(key: String) {
        fireOnce(key: key) {
            Haptics.warning()
        }
    }
}
