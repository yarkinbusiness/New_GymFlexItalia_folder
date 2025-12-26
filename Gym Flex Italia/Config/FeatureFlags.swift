//
//  FeatureFlags.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Feature flags for progressive rollout and A/B testing
final class FeatureFlags {
    
    static let shared = FeatureFlags()
    
    private init() {}
    
    // MARK: - Phase 1: MVP
    var isAuthEnabled: Bool { true }
    var isBookingEnabled: Bool { true }
    var isQRCheckinEnabled: Bool { true }
    var isGymDiscoveryEnabled: Bool { true }
    var isDashboardEnabled: Bool { true }
    
    // MARK: - Phase 2: Social Features
    var isGroupsEnabled: Bool { true }
    var isGroupChatEnabled: Bool { true }
    var isAvatarSystemEnabled: Bool { true }
    var isTypingIndicatorEnabled: Bool { false } // Phase 2.1
    
    // MARK: - Phase 3: Payment Features
    var isWalletEnabled: Bool { false }
    var isApplePayEnabled: Bool { false }
    var isInAppPurchaseEnabled: Bool { false }
    
    // MARK: - Phase 4: Advanced Features
    var isAppleWatchEnabled: Bool { false }
    var isWorkoutTrackingEnabled: Bool { false }
    var isHealthKitIntegrationEnabled: Bool { false }
    
    // MARK: - Experimental Features
    var isAdvancedAnalyticsEnabled: Bool { AppConfig.environment.isDevelopment }
    var isDebugMenuEnabled: Bool { AppConfig.environment.isDevelopment }
    var isBetaFeaturesEnabled: Bool { false }
    
    // MARK: - Demo Mode (Bypass Authentication)
    var isDemoMode: Bool { false }  // Set to true to skip authentication
    
    // MARK: - UI/UX Flags
    var useEnhancedAnimations: Bool { true }
    var useHapticFeedback: Bool { true }
    var useDarkModeOnly: Bool { false }
    
    // MARK: - Performance Flags
    var enableImageCaching: Bool { true }
    var enableOfflineMode: Bool { false } // Future feature
    var enablePreloading: Bool { true }
    
    // MARK: - Helper Methods
    func isEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .auth: return isAuthEnabled
        case .booking: return isBookingEnabled
        case .qrCheckin: return isQRCheckinEnabled
        case .groups: return isGroupsEnabled
        case .groupChat: return isGroupChatEnabled
        case .avatar: return isAvatarSystemEnabled
        case .wallet: return isWalletEnabled
        case .applePay: return isApplePayEnabled
        case .appleWatch: return isAppleWatchEnabled
        }
    }
    
    enum Feature {
        case auth
        case booking
        case qrCheckin
        case groups
        case groupChat
        case avatar
        case wallet
        case applePay
        case appleWatch
    }
}

