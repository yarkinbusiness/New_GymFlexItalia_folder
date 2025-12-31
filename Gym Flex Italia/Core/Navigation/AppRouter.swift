//
//  AppRouter.swift
//  Gym Flex Italia
//
//  Central navigation coordinator for the app
//

import SwiftUI
import Combine

/// Defines the available navigation destinations in the app
enum AppRoute: Hashable {
    case gymDetail(gymId: String)
    case groupDetail(groupId: String)
    case bookingDetail(bookingId: String)
    case editProfile
    case settings
    case wallet
    case walletTransactionDetail(transactionId: String)
    case deepLinkSimulator
}

/// Central navigation state owner for consistent navigation across the app
/// Inject via @EnvironmentObject at RootNavigationView level
@MainActor
final class AppRouter: ObservableObject {
    
    // MARK: - Tab Navigation
    
    /// Currently selected tab
    @Published var selectedTab: RootTabView.Tab = .home
    
    // MARK: - Stack Navigation
    
    /// Navigation path for the current flow
    @Published var path = NavigationPath()
    
    // MARK: - Singleton (for backwards compatibility with existing code)
    
    static let shared = AppRouter()
    
    init() {}
    
    // MARK: - Navigation Methods
    
    /// Navigate to a gym detail view
    func pushGymDetail(gymId: String) {
        path.append(AppRoute.gymDetail(gymId: gymId))
    }
    
    /// Navigate to a group detail view
    func pushGroupDetail(groupId: String) {
        path.append(AppRoute.groupDetail(groupId: groupId))
    }
    
    /// Navigate to a booking detail view
    func pushBookingDetail(bookingId: String) {
        path.append(AppRoute.bookingDetail(bookingId: bookingId))
    }
    
    /// Navigate to edit profile view
    func pushEditProfile() {
        path.append(AppRoute.editProfile)
    }
    
    /// Navigate to settings view
    func pushSettings() {
        path.append(AppRoute.settings)
    }
    
    /// Navigate to wallet view
    func pushWallet() {
        path.append(AppRoute.wallet)
    }
    
    /// Navigate to wallet transaction detail view
    func pushWalletTransactionDetail(transactionId: String) {
        path.append(AppRoute.walletTransactionDetail(transactionId: transactionId))
    }
    
    /// Pop the top view from the navigation stack
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// Reset navigation to root (clear entire stack)
    func resetToRoot() {
        path = NavigationPath()
    }
    
    /// Pop to root and switch to a specific tab
    func switchToTab(_ tab: RootTabView.Tab) {
        resetToRoot()
        selectedTab = tab
    }
    
    // MARK: - Convenience Methods
    
    /// Navigate to Discover tab
    func navigateToDiscover() {
        switchToTab(.discover)
    }
    
    /// Navigate to Profile tab
    func navigateToProfile() {
        switchToTab(.profile)
    }
    
    /// Navigate to Check-in tab
    func navigateToCheckIn() {
        switchToTab(.checkIn)
    }
    
    // MARK: - Deep Link Handling
    
    /// Handles deep link navigation from notifications, URLs, or other external sources
    /// Navigation is idempotent - repeated calls with the same link won't stack duplicates
    func handle(deepLink: DeepLink) {
        DemoTapLogger.log("AppRouter.HandleDeepLink", context: "\(deepLink)")
        
        switch deepLink {
        case .bookSession:
            // Navigate to Discover tab where users can find and book gyms
            // Reset navigation stack to ensure clean state
            resetToRoot()
            ensureOnTab(.discover)
            
        case .wallet:
            // Navigate to Profile tab and push wallet screen
            resetToRoot()
            ensureOnTab(.profile)
            pushIfNotTop(.wallet)
            
        case .walletTransaction(let transactionId):
            // Navigate to Profile tab and push wallet, then transaction detail
            resetToRoot()
            ensureOnTab(.profile)
            pushIfNotTop(.wallet)
            pushIfNotTop(.walletTransactionDetail(transactionId: transactionId))
            
        case .editProfile:
            // Navigate to Profile tab and push edit profile
            resetToRoot()
            ensureOnTab(.profile)
            pushIfNotTop(.editProfile)
            
        case .settings:
            // Navigate to Profile tab and push settings
            resetToRoot()
            ensureOnTab(.profile)
            pushIfNotTop(.settings)
        }
    }
    
    // MARK: - Idempotent Navigation Helpers
    
    /// Switches to the specified tab only if not already on it
    private func ensureOnTab(_ tab: RootTabView.Tab) {
        if selectedTab != tab {
            selectedTab = tab
        }
    }
    
    /// Pushes a route only if it's not already the top of the navigation stack
    /// This prevents duplicate pushes from repeated deep link handling
    private func pushIfNotTop(_ route: AppRoute) {
        // NavigationPath doesn't expose its contents directly, so we track separately
        // For now, we just append - the resetToRoot() call ensures clean state
        path.append(route)
    }
    
    /// Navigate to the deep link simulator (debug only)
    func pushDeepLinkSimulator() {
        path.append(AppRoute.deepLinkSimulator)
    }
}
