//
//  Gym_Flex_ItaliaApp.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

@main
struct Gym_Flex_ItaliaApp: App {
    
    // Initialize services
    @StateObject private var authService = AuthService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var appearanceManager = AppearanceManager.shared
    @StateObject private var bookingManager = BookingManager.shared
    
    init() {
        // App configuration
        configureApp()
    }
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(appearanceManager)
                .environmentObject(bookingManager)
                .preferredColorScheme(appearanceManager.colorScheme)
                .onAppear {
                    // Request location permission
                    locationService.requestLocationPermission()
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
}
