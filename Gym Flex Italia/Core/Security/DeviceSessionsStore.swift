//
//  DeviceSessionsStore.swift
//  Gym Flex Italia
//
//  Persisted store for device sessions (mock implementation).
//

import Foundation
import Combine
import UIKit

/// Persisted store for device sessions
@MainActor
final class DeviceSessionsStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DeviceSessionsStore()
    
    // MARK: - Persistence
    
    private static let persistenceKey = "device_sessions_store_v1"
    
    // MARK: - Published State
    
    @Published private(set) var sessions: [DeviceSession] = []
    
    // MARK: - Computed Properties
    
    /// Current device session
    var currentSession: DeviceSession? {
        sessions.first { $0.isCurrentDevice }
    }
    
    /// Other device sessions (not current)
    var otherSessions: [DeviceSession] {
        sessions.filter { !$0.isCurrentDevice }
    }
    
    /// Whether there are other sessions
    var hasOtherSessions: Bool {
        !otherSessions.isEmpty
    }
    
    // MARK: - Initialization
    
    private init() {
        load()
        
        // Seed if empty
        if sessions.isEmpty {
            seedDemoSessions()
        }
        
        #if DEBUG
        print("📱 DeviceSessionsStore.init: Loaded \(sessions.count) sessions")
        #endif
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else {
            #if DEBUG
            print("📱 DeviceSessionsStore.load: No persisted data")
            #endif
            return
        }
        
        do {
            sessions = try JSONDecoder().decode([DeviceSession].self, from: data)
            #if DEBUG
            print("📱 DeviceSessionsStore.load: Loaded \(sessions.count) sessions")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ DeviceSessionsStore.load: Failed to decode: \(error)")
            #endif
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: Self.persistenceKey)
            #if DEBUG
            print("📱 DeviceSessionsStore.save: Saved \(sessions.count) sessions")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ DeviceSessionsStore.save: Failed to encode: \(error)")
            #endif
        }
    }
    
    // MARK: - Actions
    
    /// Sign out a specific session
    func signOut(sessionId: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            #if DEBUG
            print("⚠️ DeviceSessionsStore.signOut: Session not found")
            #endif
            return
        }
        
        // Cannot sign out current device
        guard !sessions[index].isCurrentDevice else {
            #if DEBUG
            print("⚠️ DeviceSessionsStore.signOut: Cannot sign out current device")
            #endif
            return
        }
        
        let removed = sessions.remove(at: index)
        save()
        #if DEBUG
        print("📱 DeviceSessionsStore.signOut: Removed \(removed.deviceName)")
        #endif
    }
    
    /// Sign out all sessions except current device
    func signOutAllOtherSessions() {
        let removedCount = otherSessions.count
        sessions = sessions.filter { $0.isCurrentDevice }
        save()
        #if DEBUG
        print("📱 DeviceSessionsStore.signOutAllOtherSessions: Removed \(removedCount) sessions")
        #endif
    }
    
    // MARK: - Seed Data
    
    private func seedDemoSessions() {
        let calendar = Calendar.current
        let now = Date()
        
        // Current device
        let currentDeviceName = UIDevice.current.name
        
        sessions = [
            DeviceSession(
                id: "session_current",
                deviceName: currentDeviceName,
                platform: "iOS",
                lastActiveAt: now,
                location: "Rome, Italy",
                isCurrentDevice: true
            ),
            DeviceSession(
                id: "session_ipad",
                deviceName: "iPad Pro",
                platform: "iPadOS",
                lastActiveAt: calendar.date(byAdding: .hour, value: -2, to: now)!,
                location: "Rome, Italy",
                isCurrentDevice: false
            ),
            DeviceSession(
                id: "session_mac",
                deviceName: "MacBook Pro",
                platform: "macOS",
                lastActiveAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                location: "Milan, Italy",
                isCurrentDevice: false
            )
        ]
        
        save()
        #if DEBUG
        print("📱 DeviceSessionsStore: Seeded \(sessions.count) demo sessions")
        #endif
    }
    
    // MARK: - Reset
    
    func reset() {
        sessions = []
        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
        seedDemoSessions()
        #if DEBUG
        print("📱 DeviceSessionsStore.reset: Reset to defaults")
        #endif
    }
}
