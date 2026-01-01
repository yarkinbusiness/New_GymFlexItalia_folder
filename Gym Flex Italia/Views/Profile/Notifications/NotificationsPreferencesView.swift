//
//  NotificationsPreferencesView.swift
//  Gym Flex Italia
//
//  View for managing notification preferences.
//

import SwiftUI

/// Notifications and preferences view
struct NotificationsPreferencesView: View {
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var permissionManager: NotificationPermissionManager
    @ObservedObject var prefsStore = NotificationsPreferencesStore.shared
    
    var body: some View {
        List {
            // Permission Status
            permissionStatusSection
            
            // Notification Types
            notificationTypesSection
            
            // Reminder Timing
            reminderTimingSection
            
            // Quiet Hours
            quietHoursSection
            
            #if DEBUG
            // Debug Section
            debugSection
            #endif
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await permissionManager.refreshStatus()
        }
    }
    
    // MARK: - Permission Status Section
    
    private var permissionStatusSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: permissionManager.statusIcon)
                        .font(.system(size: 20))
                        .foregroundColor(statusColor)
                }
                
                // Status Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                    
                    Text(permissionManager.statusDescription)
                        .font(AppFonts.caption)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Action Button
                if permissionManager.canRequest {
                    Button("Enable") {
                        DemoTapLogger.log("Notifications.RequestPermission")
                        Task {
                            await permissionManager.requestPermission()
                        }
                    }
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(AppColors.brand)
                    .clipShape(Capsule())
                } else if permissionManager.status == .denied {
                    Button("Settings") {
                        DemoTapLogger.log("Notifications.OpenSettings")
                        NotificationPermissionManager.openSystemSettings()
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
                }
            }
            .padding(.vertical, Spacing.sm)
        } footer: {
            if permissionManager.status == .denied {
                Text("Notifications are disabled. Open Settings to enable them.")
            } else if permissionManager.status == .notDetermined {
                Text("Enable notifications to receive workout reminders and booking updates.")
            }
        }
    }
    
    private var statusColor: Color {
        switch permissionManager.status {
        case .authorized, .provisional, .ephemeral:
            return AppColors.success
        case .denied:
            return AppColors.danger
        case .notDetermined:
            return AppColors.warning
        @unknown default:
            return .secondary
        }
    }
    
    // MARK: - Notification Types Section
    
    private var notificationTypesSection: some View {
        Section {
            // Workout Reminders
            Toggle(isOn: $prefsStore.workoutRemindersEnabled) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(AppColors.brand)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Reminders")
                            .font(AppFonts.body)
                        
                        Text("Daily motivation and workout suggestions")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(!permissionManager.isAuthorized)
            
            // Booking Updates
            Toggle(isOn: $prefsStore.bookingUpdatesEnabled) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(AppColors.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Booking Updates")
                            .font(AppFonts.body)
                        
                        Text("Session reminders and changes")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(!permissionManager.isAuthorized)
            
            // Wallet Activity
            Toggle(isOn: $prefsStore.walletActivityEnabled) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(AppColors.success)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wallet Activity")
                            .font(AppFonts.body)
                        
                        Text("Top-ups, payments, and low balance alerts")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(!permissionManager.isAuthorized)
            
            // Group Activity
            Toggle(isOn: $prefsStore.groupActivityEnabled) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(Color.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Group Activity")
                            .font(AppFonts.body)
                        
                        Text("New messages and group updates")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(!permissionManager.isAuthorized)
        } header: {
            Text("Notification Types")
        } footer: {
            if !permissionManager.isAuthorized {
                Text("Enable notifications above to configure these preferences.")
            }
        }
    }
    
    // MARK: - Reminder Timing Section
    
    private var reminderTimingSection: some View {
        Section {
            DatePicker(
                "Daily Reminder Time",
                selection: Binding(
                    get: { prefsStore.preferredReminderTime },
                    set: { prefsStore.preferredReminderTime = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!permissionManager.isAuthorized || !prefsStore.workoutRemindersEnabled)
        } header: {
            Text("Reminder Schedule")
        } footer: {
            Text("Time for daily workout reminder notifications.")
        }
    }
    
    // MARK: - Quiet Hours Section
    
    private var quietHoursSection: some View {
        Section {
            Toggle("Quiet Hours", isOn: $prefsStore.quietHoursEnabled)
                .disabled(!permissionManager.isAuthorized)
            
            if prefsStore.quietHoursEnabled {
                DatePicker(
                    "Start",
                    selection: Binding(
                        get: { prefsStore.quietHoursStart },
                        set: { prefsStore.quietHoursStart = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .disabled(!permissionManager.isAuthorized)
                
                DatePicker(
                    "End",
                    selection: Binding(
                        get: { prefsStore.quietHoursEnd },
                        set: { prefsStore.quietHoursEnd = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .disabled(!permissionManager.isAuthorized)
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            if prefsStore.quietHoursEnabled {
                Text("Notifications will be silenced from \(prefsStore.quietHoursString).")
            } else {
                Text("Silence notifications during specific hours.")
            }
        }
    }
    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        Section {
            HStack {
                Text("Status Raw Value")
                Spacer()
                Text("\(permissionManager.status.rawValue)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("isAuthorized")
                Spacer()
                Text(permissionManager.isAuthorized ? "Yes" : "No")
                    .foregroundColor(permissionManager.isAuthorized ? AppColors.success : AppColors.danger)
            }
            
            HStack {
                Text("canRequest")
                Spacer()
                Text(permissionManager.canRequest ? "Yes" : "No")
                    .foregroundColor(.secondary)
            }
            
            Button("Refresh Status") {
                Task {
                    await permissionManager.refreshStatus()
                }
            }
        } header: {
            Text("Debug")
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        NotificationsPreferencesView()
    }
    .environmentObject(AppRouter())
    .environmentObject(NotificationPermissionManager())
}
