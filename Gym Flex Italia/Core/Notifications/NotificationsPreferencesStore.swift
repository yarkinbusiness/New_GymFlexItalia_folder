//
//  NotificationsPreferencesStore.swift
//  Gym Flex Italia
//
//  Persisted store for notification preferences.
//

import Foundation
import Combine

/// Persisted notification preferences data
struct NotificationsPreferencesData: Codable {
    var workoutRemindersEnabled: Bool
    var bookingUpdatesEnabled: Bool
    var walletActivityEnabled: Bool
    var groupActivityEnabled: Bool
    var quietHoursEnabled: Bool
    var quietHoursStartMinutes: Int  // Minutes since midnight
    var quietHoursEndMinutes: Int    // Minutes since midnight
    var preferredReminderTimeMinutes: Int  // Minutes since midnight
    
    static let defaults = NotificationsPreferencesData(
        workoutRemindersEnabled: true,
        bookingUpdatesEnabled: true,
        walletActivityEnabled: true,
        groupActivityEnabled: false,
        quietHoursEnabled: false,
        quietHoursStartMinutes: 22 * 60,  // 10:00 PM
        quietHoursEndMinutes: 7 * 60,     // 7:00 AM
        preferredReminderTimeMinutes: 19 * 60  // 7:00 PM
    )
}

/// Persisted store for notification preferences
@MainActor
final class NotificationsPreferencesStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationsPreferencesStore()
    
    // MARK: - Persistence
    
    private static let persistenceKey = "notifications_preferences_store_v1"
    
    // MARK: - Published State
    
    @Published var workoutRemindersEnabled: Bool = true {
        didSet { save() }
    }
    
    @Published var bookingUpdatesEnabled: Bool = true {
        didSet { save() }
    }
    
    @Published var walletActivityEnabled: Bool = true {
        didSet { save() }
    }
    
    @Published var groupActivityEnabled: Bool = false {
        didSet { save() }
    }
    
    @Published var quietHoursEnabled: Bool = false {
        didSet { save() }
    }
    
    @Published var quietHoursStartMinutes: Int = 22 * 60 {
        didSet { save() }
    }
    
    @Published var quietHoursEndMinutes: Int = 7 * 60 {
        didSet { save() }
    }
    
    @Published var preferredReminderTimeMinutes: Int = 19 * 60 {
        didSet { save() }
    }
    
    // MARK: - Computed Properties
    
    /// Preferred reminder time as Date (for DatePicker binding)
    var preferredReminderTime: Date {
        get {
            minutesToDate(preferredReminderTimeMinutes)
        }
        set {
            preferredReminderTimeMinutes = dateToMinutes(newValue)
        }
    }
    
    /// Quiet hours start as Date
    var quietHoursStart: Date {
        get {
            minutesToDate(quietHoursStartMinutes)
        }
        set {
            quietHoursStartMinutes = dateToMinutes(newValue)
        }
    }
    
    /// Quiet hours end as Date
    var quietHoursEnd: Date {
        get {
            minutesToDate(quietHoursEndMinutes)
        }
        set {
            quietHoursEndMinutes = dateToMinutes(newValue)
        }
    }
    
    /// Formatted preferred reminder time string
    var preferredReminderTimeString: String {
        formatMinutesAsTime(preferredReminderTimeMinutes)
    }
    
    /// Formatted quiet hours range string
    var quietHoursString: String {
        "\(formatMinutesAsTime(quietHoursStartMinutes)) - \(formatMinutesAsTime(quietHoursEndMinutes))"
    }
    
    // MARK: - Initialization
    
    private init() {
        load()
        print("🔔 NotificationsPreferencesStore.init: workoutReminders=\(workoutRemindersEnabled), quietHours=\(quietHoursEnabled)")
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else {
            print("🔔 NotificationsPreferencesStore.load: No persisted data, using defaults")
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(NotificationsPreferencesData.self, from: data)
            workoutRemindersEnabled = decoded.workoutRemindersEnabled
            bookingUpdatesEnabled = decoded.bookingUpdatesEnabled
            walletActivityEnabled = decoded.walletActivityEnabled
            groupActivityEnabled = decoded.groupActivityEnabled
            quietHoursEnabled = decoded.quietHoursEnabled
            quietHoursStartMinutes = decoded.quietHoursStartMinutes
            quietHoursEndMinutes = decoded.quietHoursEndMinutes
            preferredReminderTimeMinutes = decoded.preferredReminderTimeMinutes
            print("🔔 NotificationsPreferencesStore.load: Loaded preferences")
        } catch {
            print("⚠️ NotificationsPreferencesStore.load: Failed to decode: \(error)")
        }
    }
    
    private func save() {
        let data = NotificationsPreferencesData(
            workoutRemindersEnabled: workoutRemindersEnabled,
            bookingUpdatesEnabled: bookingUpdatesEnabled,
            walletActivityEnabled: walletActivityEnabled,
            groupActivityEnabled: groupActivityEnabled,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStartMinutes: quietHoursStartMinutes,
            quietHoursEndMinutes: quietHoursEndMinutes,
            preferredReminderTimeMinutes: preferredReminderTimeMinutes
        )
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: Self.persistenceKey)
            print("🔔 NotificationsPreferencesStore.save: Saved preferences")
        } catch {
            print("⚠️ NotificationsPreferencesStore.save: Failed to encode: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func minutesToDate(_ minutes: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = minutes / 60
        components.minute = minutes % 60
        return calendar.date(from: components) ?? now
    }
    
    private func dateToMinutes(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
    
    private func formatMinutesAsTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        var components = DateComponents()
        components.hour = hours
        components.minute = mins
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return String(format: "%d:%02d", hours, mins)
    }
    
    // MARK: - Reset
    
    func reset() {
        let defaults = NotificationsPreferencesData.defaults
        workoutRemindersEnabled = defaults.workoutRemindersEnabled
        bookingUpdatesEnabled = defaults.bookingUpdatesEnabled
        walletActivityEnabled = defaults.walletActivityEnabled
        groupActivityEnabled = defaults.groupActivityEnabled
        quietHoursEnabled = defaults.quietHoursEnabled
        quietHoursStartMinutes = defaults.quietHoursStartMinutes
        quietHoursEndMinutes = defaults.quietHoursEndMinutes
        preferredReminderTimeMinutes = defaults.preferredReminderTimeMinutes
        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
        print("🔔 NotificationsPreferencesStore.reset: Reset to defaults")
    }
}
