//
//  RootNavigationView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Root navigation coordinator
struct RootNavigationView: View {
    
    @StateObject private var authService = AuthService.shared
    
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
}

