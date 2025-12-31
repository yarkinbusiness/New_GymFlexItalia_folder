//
//  LocalNotificationService.swift
//  Gym Flex Italia
//
//  Live implementation of NotificationServiceProtocol using UNUserNotificationCenter
//

import Foundation
import UserNotifications
import UIKit

/// Live implementation that interacts with iOS notification system
final class LocalNotificationService: NotificationServiceProtocol {
    
    // MARK: - Constants
    
    /// Identifier for daily workout reminder notifications
    static let workoutReminderIdentifier = "gymflex_workout_reminder_daily"
    
    /// Notification category for workout reminders
    static let workoutReminderCategory = "WORKOUT_REMINDER"
    
    // MARK: - Private Properties
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    init() {
        // Register notification categories if needed
        registerCategories()
    }
    
    // MARK: - NotificationServiceProtocol
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    func requestAuthorization() async throws -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            print("📱 Notification authorization \(granted ? "granted" : "denied")")
            return granted
        } catch {
            print("❌ Notification authorization error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func scheduleWorkoutReminder(hour: Int, minute: Int) async throws {
        // Check authorization first
        let status = await getAuthorizationStatus()
        guard status == .authorized else {
            throw NotificationServiceError.authorizationDenied
        }
        
        // Cancel existing reminder first
        await cancelWorkoutReminders()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder 💪"
        content.body = "Time to train — open GymFlex to book your session."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = Self.workoutReminderCategory
        
        // Create daily trigger at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: Self.workoutReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule
        do {
            try await center.add(request)
            print("✅ Workout reminder scheduled for \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("❌ Failed to schedule workout reminder: \(error.localizedDescription)")
            throw NotificationServiceError.schedulingFailed(error.localizedDescription)
        }
    }
    
    func cancelWorkoutReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.workoutReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.workoutReminderIdentifier])
        print("🔕 Workout reminders cancelled")
    }
    
    @MainActor
    func openSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Private Methods
    
    private func registerCategories() {
        // Define actions for workout reminder
        let bookAction = UNNotificationAction(
            identifier: "BOOK_SESSION",
            title: "Book Now",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: Self.workoutReminderCategory,
            actions: [bookAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([workoutCategory])
    }
}
