//
//  NotificationPermissionManager.swift
//  Gym Flex Italia
//
//  Manages OS notification permission status and requests.
//

import Foundation
import UserNotifications
import UIKit
import Combine

/// Manages notification permission state
final class NotificationPermissionManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Current OS notification permission status
    @Published private(set) var status: UNAuthorizationStatus = .notDetermined
    
    /// Whether notifications are authorized (granted or provisional)
    @Published private(set) var isAuthorized: Bool = false
    
    /// Whether we can request permission (only true if notDetermined)
    @Published private(set) var canRequest: Bool = true
    
    // MARK: - Computed Properties
    
    /// Human-readable status description
    var statusDescription: String {
        switch status {
        case .notDetermined:
            return "Not Requested"
        case .denied:
            return "Denied"
        case .authorized:
            return "Enabled"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Icon for current status
    var statusIcon: String {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    /// Color for current status
    var statusColor: String {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return "success"
        case .denied:
            return "danger"
        case .notDetermined:
            return "warning"
        @unknown default:
            return "secondary"
        }
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the current permission status from the OS
    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        await MainActor.run {
            self.status = settings.authorizationStatus
            self.isAuthorized = (self.status == .authorized || self.status == .provisional || self.status == .ephemeral)
            self.canRequest = (self.status == .notDetermined)
        }
        
        print("🔔 NotificationPermissionManager.refreshStatus: status=\(statusDescription), authorized=\(isAuthorized)")
    }
    
    /// Requests notification permission from the OS
    /// - Returns: true if permission was granted
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            print("🔔 NotificationPermissionManager.requestPermission: granted=\(granted)")
            
            // Refresh status after request
            await refreshStatus()
            
            return granted
        } catch {
            print("⚠️ NotificationPermissionManager.requestPermission: error=\(error.localizedDescription)")
            await refreshStatus()
            return false
        }
    }
    
    /// Opens the iOS Settings app to the notification settings for this app
    static func openSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            print("⚠️ NotificationPermissionManager.openSystemSettings: Invalid settings URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL) { success in
                print("🔔 NotificationPermissionManager.openSystemSettings: opened=\(success)")
            }
        } else {
            print("⚠️ NotificationPermissionManager.openSystemSettings: Cannot open settings URL")
        }
    }
}
