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
    case groupNotFound(message: String)
    case bookingHistory
    case bookingDetail(bookingId: String)
    case editProfile
    case settings
    case wallet
    case walletTransactionDetail(transactionId: String)
    case checkIn(bookingId: String)
    case deepLinkSimulator
    case paymentMethods
    case addCard
    case accountSecurity
    case changePassword
    case devicesSessions
    case deleteAccount
    case notificationsPreferences
    case helpSupport
    case faq
    case reportBug
    case terms
    case privacy
    case editAvatar
    case updateGoals
    case ownerMode  // DEBUG-only: QR validation for gym owners
}

/// Central navigation state owner for consistent navigation across the app
/// Inject via @EnvironmentObject at RootNavigationView level
///
/// Navigation Hardening:
/// - All path modifications MUST go through AppRouter methods (appendRoute, pop, resetToRoot)
/// - `routeStack` mirrors `NavigationPath` for idempotency checks since NavigationPath doesn't expose contents
/// - System back gestures sync via `syncRouteStackWithPath()` called from path observation
/// - Debug mode assertions detect any drift between routeStack and path
@MainActor
final class AppRouter: ObservableObject {
    
    // MARK: - Tab Navigation
    
    /// Currently selected tab
    @Published var selectedTab: RootTabView.Tab = .home
    
    // MARK: - Stack Navigation
    
    /// Navigation path for the current flow
    /// Use Combine to observe changes from system back gestures
    @Published var path = NavigationPath() {
        didSet {
            syncRouteStackWithPath()
        }
    }
    
    /// Tracks routes in the current navigation path for idempotency checks
    /// NavigationPath doesn't expose its contents, so we mirror it here
    /// INVARIANT: routeStack.count should always equal path.count
    private var routeStack: [AppRoute] = []
    
    /// Flag to prevent recursive sync during programmatic updates
    private var isSyncingFromPath = false
    
    // MARK: - Singleton (for backwards compatibility with existing code)
    
    static let shared = AppRouter()
    
    init() {}
    
    // MARK: - Navigation Methods
    
    /// Navigate to a gym detail view (idempotent - won't stack duplicates)
    func pushGymDetail(gymId: String) {
        pushIfNotTop(.gymDetail(gymId: gymId))
    }
    
    /// Navigate to a group detail view
    func pushGroupDetail(groupId: String) {
        appendRoute(.groupDetail(groupId: groupId))
    }
    
    /// Navigate to booking history view
    func pushBookingHistory() {
        appendRoute(.bookingHistory)
    }
    
    /// Navigate to a booking detail view
    func pushBookingDetail(bookingId: String) {
        appendRoute(.bookingDetail(bookingId: bookingId))
    }
    
    /// Navigate to edit profile view
    func pushEditProfile() {
        appendRoute(.editProfile)
    }
    
    /// Navigate to settings view
    func pushSettings() {
        appendRoute(.settings)
    }
    
    /// Navigate to wallet view
    func pushWallet() {
        appendRoute(.wallet)
    }
    
    /// Navigate to wallet transaction detail view
    func pushWalletTransactionDetail(transactionId: String) {
        appendRoute(.walletTransactionDetail(transactionId: transactionId))
    }
    
    /// Navigate to check-in view
    func pushCheckIn(bookingId: String) {
        appendRoute(.checkIn(bookingId: bookingId))
    }
    
    /// Pop the top view from the navigation stack
    func pop() {
        guard !path.isEmpty else { return }
        isSyncingFromPath = true
        path.removeLast()
        _ = routeStack.popLast()
        isSyncingFromPath = false
        validateStackSync()
    }
    
    /// Reset navigation to root (clear entire stack)
    func resetToRoot() {
        isSyncingFromPath = true
        path = NavigationPath()
        routeStack.removeAll()
        isSyncingFromPath = false
        validateStackSync()
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
            
        case .bookingHistory:
            // Navigate to Profile tab and push booking history
            resetToRoot()
            ensureOnTab(.profile)
            pushIfNotTop(.bookingHistory)
            
        case .bookingDetail(let bookingId):
            // Navigate to Profile tab, push booking history, then booking detail
            resetToRoot()
            ensureOnTab(.profile)
            pushIfNotTop(.bookingHistory)
            pushIfNotTop(.bookingDetail(bookingId: bookingId))
            
        case .gymDetail(let gymId):
            // Navigate to Discover tab and push gym detail
            resetToRoot()
            ensureOnTab(.discover)
            pushIfNotTop(.gymDetail(gymId: gymId))
            
        case .groupInvite(let groupId):
            // Navigate to Groups tab and push group detail (for invite link handling)
            // First check if the group exists
            resetToRoot()
            ensureOnTab(.groups)
            
            // Check if group exists in store
            if MockGroupsStore.shared.groupById(groupId) != nil {
                pushIfNotTop(.groupDetail(groupId: groupId))
            } else {
                // Group not found - show error view
                pushIfNotTop(.groupNotFound(message: "Group not found or invite expired"))
            }
        }
    }
    
    // MARK: - Idempotent Navigation Helpers
    
    /// Switches to the specified tab only if not already on it
    private func ensureOnTab(_ tab: RootTabView.Tab) {
        if selectedTab != tab {
            selectedTab = tab
        }
    }
    
    /// Appends a route to the navigation stack and tracks it
    private func appendRoute(_ route: AppRoute) {
        isSyncingFromPath = true
        path.append(route)
        routeStack.append(route)
        isSyncingFromPath = false
        validateStackSync()
    }
    
    /// Pushes a route only if it's not already the top of the navigation stack
    /// This prevents duplicate pushes from repeated taps or deep link handling
    private func pushIfNotTop(_ route: AppRoute) {
        // Check if the route is already at the top of the stack
        if let topRoute = routeStack.last, topRoute == route {
            // Already at top - skip to prevent stacking duplicates
            return
        }
        appendRoute(route)
    }
    
    /// Navigate to the deep link simulator (debug only)
    #if DEBUG
    func pushDeepLinkSimulator() {
        appendRoute(.deepLinkSimulator)
    }
    
    /// Navigate to owner mode QR validator (debug only)
    func pushOwnerMode() {
        appendRoute(.ownerMode)
    }
    #endif
    
    /// Navigate to payment methods
    func pushPaymentMethods() {
        appendRoute(.paymentMethods)
    }
    
    /// Navigate to add card form
    func pushAddCard() {
        appendRoute(.addCard)
    }
    
    /// Navigate to account security
    func pushAccountSecurity() {
        appendRoute(.accountSecurity)
    }
    
    /// Navigate to change password
    func pushChangePassword() {
        appendRoute(.changePassword)
    }
    
    /// Navigate to devices and sessions
    func pushDevicesSessions() {
        appendRoute(.devicesSessions)
    }
    
    /// Navigate to delete account
    func pushDeleteAccount() {
        appendRoute(.deleteAccount)
    }
    
    /// Navigate to notifications preferences
    func pushNotificationsPreferences() {
        appendRoute(.notificationsPreferences)
    }
    
    /// Navigate to help & support
    func pushHelpSupport() {
        appendRoute(.helpSupport)
    }
    
    /// Navigate to FAQ
    func pushFAQ() {
        appendRoute(.faq)
    }
    
    /// Navigate to report bug
    func pushReportBug() {
        appendRoute(.reportBug)
    }
    
    /// Navigate to terms of service
    func pushTerms() {
        appendRoute(.terms)
    }
    
    /// Navigate to privacy policy
    func pushPrivacy() {
        appendRoute(.privacy)
    }
    
    /// Navigate to edit avatar
    func pushEditAvatar() {
        appendRoute(.editAvatar)
    }
    
    /// Navigate to update goals
    func pushUpdateGoals() {
        appendRoute(.updateGoals)
    }
    
    // MARK: - Stack Synchronization (for back gesture handling)
    
    /// Syncs routeStack when path changes externally (e.g., system back gesture)
    /// This is called from path's didSet observer
    private func syncRouteStackWithPath() {
        // Skip if we're making programmatic changes
        guard !isSyncingFromPath else { return }
        
        // If path was reduced (back gesture/button), trim routeStack to match
        if path.count < routeStack.count {
            let itemsToRemove = routeStack.count - path.count
            routeStack.removeLast(itemsToRemove)
            
            #if DEBUG
            DemoTapLogger.log("AppRouter.BackSync", context: "Removed \(itemsToRemove) items, stack now \(routeStack.count)")
            #endif
        }
        
        // Path was cleared entirely (shouldn't happen via normal back but handle it)
        if path.isEmpty && !routeStack.isEmpty {
            routeStack.removeAll()
            
            #if DEBUG
            DemoTapLogger.log("AppRouter.BackSync", context: "Path cleared, routeStack reset")
            #endif
        }
        
        validateStackSync()
    }
    
    /// Debug assertion to detect any drift between routeStack and path
    /// Called after every navigation operation
    private func validateStackSync() {
        #if DEBUG
        if routeStack.count != path.count {
            let message = "⚠️ AppRouter DESYNC: routeStack.count=\(routeStack.count) != path.count=\(path.count)"
            print(message)
            DemoTapLogger.log("AppRouter.DESYNC_WARNING", context: message)
            // In debug builds, this helps catch issues early
            // assertionFailure(message) // Uncomment to fail fast during development
        }
        #endif
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// Returns the current route stack for debugging
    var debugRouteStack: [AppRoute] {
        routeStack
    }
    
    /// Returns whether the navigation state is synchronized
    var isStackSynchronized: Bool {
        routeStack.count == path.count
    }
    #endif
}
