//
//  RootNavigationView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Root navigation coordinator
struct RootNavigationView: View {
    
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            // Demo mode: Skip authentication for testing
            if FeatureFlags.shared.isDemoMode {
                RootTabView()
            } else if authService.isAuthenticated {
                RootTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    RootNavigationView()
        .environmentObject(AppRouter())
        .environmentObject(AuthService.shared)
        .environmentObject(LocationService.shared)
        .environmentObject(AppearanceManager.shared)
        .environmentObject(BookingManager.shared)
        .environmentObject(SettingsStore())
        .environment(\.appContainer, .demo())
}

