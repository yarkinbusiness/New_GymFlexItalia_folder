//
//  SecuritySettingsStore.swift
//  Gym Flex Italia
//
//  Persisted store for security settings.
//

import Foundation
import Combine

/// Persisted security settings data
struct SecuritySettingsData: Codable {
    var biometricLockEnabled: Bool
    var requireBiometricOnLaunch: Bool
    var twoFactorEnabled: Bool
    var lastPasswordChangeAt: Date?
    
    static let defaults = SecuritySettingsData(
        biometricLockEnabled: false,
        requireBiometricOnLaunch: false,
        twoFactorEnabled: false,
        lastPasswordChangeAt: nil
    )
}

/// Persisted store for security settings
@MainActor
final class SecuritySettingsStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SecuritySettingsStore()
    
    // MARK: - Persistence
    
    private static let persistenceKey = "security_settings_store_v1"
    
    // MARK: - Published State
    
    @Published var biometricLockEnabled: Bool = false {
        didSet { save() }
    }
    
    @Published var requireBiometricOnLaunch: Bool = false {
        didSet { save() }
    }
    
    @Published var twoFactorEnabled: Bool = false {
        didSet { save() }
    }
    
    @Published var lastPasswordChangeAt: Date? = nil {
        didSet { save() }
    }
    
    // MARK: - Computed Properties
    
    /// Formatted last password change
    var lastPasswordChangeFormatted: String? {
        guard let date = lastPasswordChangeAt else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Initialization
    
    private init() {
        load()
        #if DEBUG
        print("🔐 SecuritySettingsStore.init: biometric=\(biometricLockEnabled), 2FA=\(twoFactorEnabled)")
        #endif
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else {
            #if DEBUG
            print("🔐 SecuritySettingsStore.load: No persisted data, using defaults")
            #endif
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(SecuritySettingsData.self, from: data)
            biometricLockEnabled = decoded.biometricLockEnabled
            requireBiometricOnLaunch = decoded.requireBiometricOnLaunch
            twoFactorEnabled = decoded.twoFactorEnabled
            lastPasswordChangeAt = decoded.lastPasswordChangeAt
            #if DEBUG
            print("🔐 SecuritySettingsStore.load: Loaded settings")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ SecuritySettingsStore.load: Failed to decode: \(error)")
            #endif
        }
    }
    
    private func save() {
        let data = SecuritySettingsData(
            biometricLockEnabled: biometricLockEnabled,
            requireBiometricOnLaunch: requireBiometricOnLaunch,
            twoFactorEnabled: twoFactorEnabled,
            lastPasswordChangeAt: lastPasswordChangeAt
        )
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: Self.persistenceKey)
            #if DEBUG
            print("🔐 SecuritySettingsStore.save: Saved settings")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ SecuritySettingsStore.save: Failed to encode: \(error)")
            #endif
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        biometricLockEnabled = false
        requireBiometricOnLaunch = false
        twoFactorEnabled = false
        lastPasswordChangeAt = nil
        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
        #if DEBUG
        print("🔐 SecuritySettingsStore.reset: Cleared all settings")
        #endif
    }
}
