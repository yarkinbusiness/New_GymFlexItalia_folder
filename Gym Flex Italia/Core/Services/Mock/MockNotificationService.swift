//
//  MockNotificationService.swift
//  Gym Flex Italia
//
//  Mock implementation of NotificationServiceProtocol for demo/testing
//

import Foundation
import UserNotifications
import UIKit

/// Mock implementation for demo mode
/// Always succeeds without triggering real iOS permission prompts
final class MockNotificationService: NotificationServiceProtocol {
    
    // MARK: - Mock State
    
    /// Simulated authorization status (defaults to authorized in demo)
    private var mockAuthorizationStatus: UNAuthorizationStatus = .authorized
    
    /// Simulated scheduled reminders
    private var scheduledReminders: [String] = []
    
    /// Whether to simulate permission denied (for testing denied flow)
    var simulateDenied: Bool = false
    
    // MARK: - NotificationServiceProtocol
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        // Simulate small delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        if simulateDenied {
            DemoTapLogger.log("MockNotification.GetStatus", context: "denied")
            return .denied
        }
        
        DemoTapLogger.log("MockNotification.GetStatus", context: "authorized")
        return mockAuthorizationStatus
    }
    
    func requestAuthorization() async throws -> Bool {
        DemoTapLogger.log("MockNotification.RequestAuthorization")
        
        // Simulate small delay for "requesting"
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        if simulateDenied {
            mockAuthorizationStatus = .denied
            print("📱 [Mock] Notification authorization denied (simulated)")
            return false
        }
        
        mockAuthorizationStatus = .authorized
        print("📱 [Mock] Notification authorization granted (simulated)")
        return true
    }
    
    func scheduleWorkoutReminder(hour: Int, minute: Int) async throws {
        DemoTapLogger.log("MockNotification.ScheduleReminder", context: "\(hour):\(String(format: "%02d", minute))")
        
        // Simulate small delay
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        if simulateDenied {
            throw NotificationServiceError.authorizationDenied
        }
        
        let identifier = "gymflex_workout_reminder_daily"
        scheduledReminders.append(identifier)
        print("✅ [Mock] Workout reminder scheduled for \(hour):\(String(format: "%02d", minute))")
    }
    
    func cancelWorkoutReminders() async {
        DemoTapLogger.log("MockNotification.CancelReminders")
        
        scheduledReminders.removeAll { $0 == "gymflex_workout_reminder_daily" }
        print("🔕 [Mock] Workout reminders cancelled")
    }
    
    @MainActor
    func openSystemSettings() {
        DemoTapLogger.log("MockNotification.OpenSettings")
        print("⚙️ [Mock] Would open system settings in live mode")
        
        // In demo mode, we still open settings so user can see it works
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
