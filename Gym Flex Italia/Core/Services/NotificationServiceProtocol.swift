//
//  NotificationServiceProtocol.swift
//  Gym Flex Italia
//
//  Protocol defining notification-related operations
//

import Foundation
import UserNotifications

/// Protocol for notification service operations
protocol NotificationServiceProtocol {
    /// Gets the current authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    
    /// Requests notification authorization from the user
    /// - Returns: true if granted, false otherwise
    func requestAuthorization() async throws -> Bool
    
    /// Schedules a daily workout reminder
    /// - Parameters:
    ///   - hour: Hour of day (0-23)
    ///   - minute: Minute (0-59)
    func scheduleWorkoutReminder(hour: Int, minute: Int) async throws
    
    /// Cancels all scheduled workout reminders
    func cancelWorkoutReminders() async
    
    /// Opens the iOS Settings app to this app's settings page
    func openSystemSettings()
}

/// Errors that can occur during notification operations
enum NotificationServiceError: Error, LocalizedError {
    case authorizationDenied
    case authorizationNotDetermined
    case schedulingFailed(String)
    case permissionRequired
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Notification permission was denied. Please enable notifications in Settings."
        case .authorizationNotDetermined:
            return "Notification permission has not been requested yet."
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        case .permissionRequired:
            return "Push notifications must be enabled to use this feature."
        }
    }
}
