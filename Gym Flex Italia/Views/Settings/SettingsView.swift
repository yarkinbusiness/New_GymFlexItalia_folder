//
//  SettingsView.swift
//  Gym Flex Italia
//
//  App settings screen with persistence and appearance control
//

import SwiftUI

/// Settings screen with appearance, notifications, privacy, and debug options
struct SettingsView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var router: AppRouter
    
    // Reset confirmation
    @State private var showResetConfirmation = false
    @State private var showExportCopied = false
    
    // Notification states
    @State private var showPermissionDeniedAlert = false
    @State private var notificationErrorMessage: String?
    @State private var notificationSuccessMessage: String?
    @State private var isProcessingNotification = false
    
    var body: some View {
        Form {
            // Notification feedback messages
            if let error = notificationErrorMessage {
                Section {
                    InlineErrorBanner(
                        message: error,
                        type: .error,
                        onDismiss: { notificationErrorMessage = nil }
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            if let success = notificationSuccessMessage {
                Section {
                    InlineErrorBanner(
                        message: success,
                        type: .success,
                        onDismiss: { notificationSuccessMessage = nil }
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Appearance Section
            appearanceSection
            
            // Notifications Section
            notificationsSection
            
            // Location Section
            locationSection
            
            // Haptics & Sound Section
            hapticsSection
            
            // Privacy Section
            privacySection
            
            // Localization Section
            localizationSection
            
            // About Section
            aboutSection
            
            // Debug Section (Demo mode only)
            if FeatureFlags.shared.isDemoMode {
                debugSection
            }
            
            // Reset Section
            resetSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                DemoTapLogger.log("Settings.ResetConfirmed")
                Task {
                    await appContainer.notificationService.cancelWorkoutReminders()
                }
                settingsStore.resetToDefaults()
                applyAppearance()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                DemoTapLogger.log("Settings.OpenSystemSettings")
                appContainer.notificationService.openSystemSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Notifications are disabled for this app. To receive reminders, please enable notifications in Settings.")
        }
        .alert("Settings Exported", isPresented: $showExportCopied) {
            Button("OK") { }
        } message: {
            Text("Settings JSON has been printed to the console.")
        }
        .onChange(of: settingsStore.settings.appearanceMode) { _, newMode in
            applyAppearance()
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            Picker(selection: $settingsStore.settings.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    HStack {
                        Image(systemName: mode.icon)
                        Text(mode.displayName)
                    }
                    .tag(mode)
                }
            } label: {
                SettingsRow(
                    icon: "paintbrush.fill",
                    iconColor: .purple,
                    title: "Appearance"
                )
            }
            .onChange(of: settingsStore.settings.appearanceMode) { _, _ in
                DemoTapLogger.log("Settings.AppearanceChanged")
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose how Gym Flex Italia looks. System follows your device settings.")
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            // Push Notifications Toggle
            HStack {
                Toggle(isOn: Binding(
                    get: { settingsStore.settings.enablePushNotifications },
                    set: { newValue in
                        if newValue {
                            handleEnablePushNotifications()
                        } else {
                            handleDisablePushNotifications()
                        }
                    }
                )) {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .red,
                        title: "Push Notifications"
                    )
                }
                .disabled(isProcessingNotification)
                
                if isProcessingNotification {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Workout Reminders Toggle
            HStack {
                Toggle(isOn: Binding(
                    get: { settingsStore.settings.enableWorkoutReminders },
                    set: { newValue in
                        if newValue {
                            handleEnableWorkoutReminders()
                        } else {
                            handleDisableWorkoutReminders()
                        }
                    }
                )) {
                    SettingsRow(
                        icon: "alarm.fill",
                        iconColor: .orange,
                        title: "Workout Reminders"
                    )
                }
                .disabled(isProcessingNotification || !settingsStore.settings.enablePushNotifications)
            }
            
            // Show reminder time info if enabled
            if settingsStore.settings.enableWorkoutReminders {
                HStack {
                    Text("Daily at 7:00 PM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.leading, 40)
            }
        } header: {
            Text("Notifications")
        } footer: {
            if !settingsStore.settings.enablePushNotifications {
                Text("Enable Push Notifications first to receive workout reminders.")
            } else {
                Text("Get reminded to work out every day at 7:00 PM.")
            }
        }
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        Section {
            Toggle(isOn: $settingsStore.settings.enableLocationFeatures) {
                SettingsRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Location Features"
                )
            }
            .onChange(of: settingsStore.settings.enableLocationFeatures) { _, newValue in
                DemoTapLogger.log("Settings.ToggleLocation", context: "enabled: \(newValue)")
            }
        } header: {
            Text("Location")
        } footer: {
            Text("Enable to find nearby gyms and get distance information.")
        }
    }
    
    // MARK: - Haptics Section
    
    private var hapticsSection: some View {
        Section {
            Toggle(isOn: $settingsStore.settings.enableHaptics) {
                SettingsRow(
                    icon: "hand.tap.fill",
                    iconColor: .green,
                    title: "Haptic Feedback"
                )
            }
            .onChange(of: settingsStore.settings.enableHaptics) { _, newValue in
                DemoTapLogger.log("Settings.ToggleHaptics", context: "enabled: \(newValue)")
            }
            
            Toggle(isOn: $settingsStore.settings.enableSoundEffects) {
                SettingsRow(
                    icon: "speaker.wave.2.fill",
                    iconColor: .teal,
                    title: "Sound Effects"
                )
            }
            .onChange(of: settingsStore.settings.enableSoundEffects) { _, newValue in
                DemoTapLogger.log("Settings.ToggleSounds", context: "enabled: \(newValue)")
            }
        } header: {
            Text("Haptics & Sound")
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            Toggle(isOn: $settingsStore.settings.privacyAnalyticsOptIn) {
                SettingsRow(
                    icon: "chart.bar.fill",
                    iconColor: .indigo,
                    title: "Share Analytics"
                )
            }
            .onChange(of: settingsStore.settings.privacyAnalyticsOptIn) { _, newValue in
                DemoTapLogger.log("Settings.ToggleAnalytics", context: "enabled: \(newValue)")
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("Help us improve the app by sharing anonymous usage data.")
        }
    }
    
    // MARK: - Localization Section
    
    private var localizationSection: some View {
        Section {
            Picker(selection: $settingsStore.settings.measurementSystem) {
                ForEach(MeasurementSystem.allCases, id: \.self) { system in
                    Text(system.displayName).tag(system)
                }
            } label: {
                SettingsRow(
                    icon: "ruler.fill",
                    iconColor: .brown,
                    title: "Measurement System"
                )
            }
            .onChange(of: settingsStore.settings.measurementSystem) { _, _ in
                DemoTapLogger.log("Settings.MeasurementChanged")
            }
        } header: {
            Text("Units")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "Version"
                )
                Spacer()
                Text(AppConfig.App.fullVersion)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                SettingsRow(
                    icon: "hammer.fill",
                    iconColor: .gray,
                    title: "Build"
                )
                Spacer()
                Text(AppConfig.App.build)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                SettingsRow(
                    icon: "gearshape.2.fill",
                    iconColor: .gray,
                    title: "Environment"
                )
                Spacer()
                Text(AppConfig.environment.rawValue.capitalized)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Debug Section
    
    private var debugSection: some View {
        Section {
            Button {
                DemoTapLogger.log("Settings.ExportJSON")
                settingsStore.printDebugSettings()
                showExportCopied = true
            } label: {
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .cyan,
                    title: "Export Settings JSON"
                )
            }
            
            HStack {
                SettingsRow(
                    icon: "flag.fill",
                    iconColor: .mint,
                    title: "Demo Mode"
                )
                Spacer()
                Text("Enabled")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Capsule())
            }
        } header: {
            Text("Debug")
        } footer: {
            Text("Developer options. Only visible in demo mode.")
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                DemoTapLogger.log("Settings.Reset")
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Reset All Settings")
                    Spacer()
                }
            }
        } footer: {
            Text("This will restore all settings to their default values.")
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleEnablePushNotifications() {
        DemoTapLogger.log("Settings.PushPermissionRequest")
        isProcessingNotification = true
        notificationErrorMessage = nil
        notificationSuccessMessage = nil
        
        Task {
            do {
                let granted = try await appContainer.notificationService.requestAuthorization()
                
                await MainActor.run {
                    isProcessingNotification = false
                    
                    if granted {
                        settingsStore.settings.enablePushNotifications = true
                        notificationSuccessMessage = "Notifications enabled! You'll receive updates from GymFlex."
                    } else {
                        settingsStore.settings.enablePushNotifications = false
                        showPermissionDeniedAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingNotification = false
                    settingsStore.settings.enablePushNotifications = false
                    notificationErrorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleDisablePushNotifications() {
        DemoTapLogger.log("Settings.DisablePushNotifications")
        settingsStore.settings.enablePushNotifications = false
        
        // Also disable workout reminders since they depend on push
        if settingsStore.settings.enableWorkoutReminders {
            handleDisableWorkoutReminders()
        }
    }
    
    private func handleEnableWorkoutReminders() {
        DemoTapLogger.log("Settings.EnableWorkoutReminders")
        
        // Check if push notifications are enabled first
        guard settingsStore.settings.enablePushNotifications else {
            notificationErrorMessage = "Please enable Push Notifications first to receive workout reminders."
            return
        }
        
        isProcessingNotification = true
        notificationErrorMessage = nil
        notificationSuccessMessage = nil
        
        Task {
            do {
                // Schedule reminder for 7:00 PM (19:00)
                try await appContainer.notificationService.scheduleWorkoutReminder(hour: 19, minute: 0)
                
                await MainActor.run {
                    isProcessingNotification = false
                    settingsStore.settings.enableWorkoutReminders = true
                    notificationSuccessMessage = "Workout reminder scheduled for 7:00 PM daily!"
                }
            } catch {
                await MainActor.run {
                    isProcessingNotification = false
                    settingsStore.settings.enableWorkoutReminders = false
                    
                    if case NotificationServiceError.authorizationDenied = error {
                        showPermissionDeniedAlert = true
                    } else {
                        notificationErrorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func handleDisableWorkoutReminders() {
        DemoTapLogger.log("Settings.DisableWorkoutReminders")
        
        Task {
            await appContainer.notificationService.cancelWorkoutReminders()
            
            await MainActor.run {
                settingsStore.settings.enableWorkoutReminders = false
                notificationSuccessMessage = "Workout reminders turned off."
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func applyAppearance() {
        switch settingsStore.settings.appearanceMode {
        case .system:
            // For system mode, the preferredColorScheme(nil) in the app root handles this
            break
        case .light:
            appearanceManager.setColorScheme(.light)
        case .dark:
            appearanceManager.setColorScheme(.dark)
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(SettingsStore())
    .environmentObject(AppearanceManager.shared)
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
