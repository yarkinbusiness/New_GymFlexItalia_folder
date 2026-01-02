//
//  Gym_Flex_ItaliaApp.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI
import UserNotifications

@main
struct Gym_Flex_ItaliaApp: App {
    
    // Initialize services
    @StateObject private var authService = AuthService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var appearanceManager = AppearanceManager.shared
    @StateObject private var bookingManager = BookingManager.shared
    
    // Navigation router
    @StateObject private var router = AppRouter()
    
    // Settings store (persists to UserDefaults)
    @StateObject private var settingsStore = SettingsStore()
    
    // Deep link queue for buffering links during cold start
    @StateObject private var deepLinkQueue = DeepLinkQueue()
    
    // Notification permission manager
    @StateObject private var notificationPermissionManager = NotificationPermissionManager()
    
    // Notification action handler (kept alive for delegate callbacks)
    private let notificationHandler = NotificationActionHandler()
    
    // Dependency injection container (uses mock services for now)
    private let appContainer = AppContainer.demo()
    
    init() {
        // App configuration
        configureApp()
    }
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environment(\.appContainer, appContainer)
                .environmentObject(authService)
                .environmentObject(locationService)
                .environmentObject(appearanceManager)
                .environmentObject(bookingManager)
                .environmentObject(router)
                .environmentObject(settingsStore)
                .environmentObject(deepLinkQueue)
                .environmentObject(notificationPermissionManager)
                .preferredColorScheme(settingsStore.preferredColorScheme)
                .withGFTheme() // Inject design system theme
                .onAppear {
                    // Request location permission
                    locationService.requestLocationPermission()
                    // Sync appearance with settings
                    syncAppearanceWithSettings()
                    // Wire up notification action handler
                    setupNotificationHandler()
                }
                .task {
                    // Refresh notification permission status on launch
                    await notificationPermissionManager.refreshStatus()
                }
                .onOpenURL { url in
                    // Handle invite link URLs (gymflex://invite?groupId=...)
                    if let deepLink = InviteLinkParser.parse(url: url) {
                        print("🔗 App received URL: \(url.absoluteString)")
                        deepLinkQueue.enqueue(deepLink)
                    }
                }
        }
    }
    
    private func configureApp() {
        // Configure appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Log app info
        print("🏋️ GymFlex Italia")
        print("📱 Version: \(AppConfig.App.fullVersion)")
        print("🌍 AppEnvironment: \(AppConfig.environment.rawValue)")
        print("⚙️ Features: Auth: \(FeatureFlags.shared.isAuthEnabled), Groups: \(FeatureFlags.shared.isGroupsEnabled), Wallet: \(FeatureFlags.shared.isWalletEnabled)")
    }
    
    private func syncAppearanceWithSettings() {
        // Sync AppearanceManager with persisted settings on launch
        switch settingsStore.settings.appearanceMode {
        case .light:
            appearanceManager.setColorScheme(.light)
        case .dark:
            appearanceManager.setColorScheme(.dark)
        case .system:
            // System mode - preferredColorScheme(nil) handles this
            break
        }
    }
    
    private func setupNotificationHandler() {
        // Set up deep link callback to enqueue for deferred processing
        // This ensures deep links work even on cold start before UI is ready
        notificationHandler.onDeepLink = { [weak deepLinkQueue] deepLink in
            DispatchQueue.main.async {
                deepLinkQueue?.enqueue(deepLink)
            }
        }
        
        // Set as notification center delegate
        UNUserNotificationCenter.current().delegate = notificationHandler
    }
}
