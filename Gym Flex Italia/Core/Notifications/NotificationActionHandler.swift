//
//  NotificationActionHandler.swift
//  Gym Flex Italia
//
//  Handles notification responses and routes to appropriate app screens
//

import Foundation
import UserNotifications

/// Handles user interactions with notifications and triggers deep link navigation
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    
    // MARK: - Deep Link Callback
    
    /// Callback to handle deep links - set this to route to AppRouter
    var onDeepLink: ((DeepLink) -> Void)?
    
    // MARK: - Notification Action Identifiers
    
    /// Action identifier for "Book Now" button on workout reminders
    private static let bookSessionActionId = "BOOK_SESSION"
    
    /// Action identifier for "Dismiss" button on workout reminders
    private static let dismissActionId = "DISMISS"
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when user interacts with a notification (taps it or an action button)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case Self.bookSessionActionId:
            // User tapped "Book Now" action button
            DemoTapLogger.log("Notification.Action.BookSession")
            onDeepLink?(.bookSession)
            
        case Self.dismissActionId:
            // User tapped "Dismiss" action button - no navigation needed
            DemoTapLogger.log("Notification.Action.Dismiss")
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body itself (default action)
            DemoTapLogger.log("Notification.Action.Default")
            // Treat default tap as navigating to book a session
            onDeepLink?(.bookSession)
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification (swipe away)
            DemoTapLogger.log("Notification.Action.SwipeDismiss")
            
        default:
            // Unknown action
            DemoTapLogger.log("Notification.Action.Unknown", context: "actionId: \(actionIdentifier)")
        }
        
        completionHandler()
    }
    
    /// Called when a notification is about to be presented while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        DemoTapLogger.log("Notification.WillPresent", context: "id: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge])
    }
}

