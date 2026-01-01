//
//  AppContainer.swift
//  Gym Flex Italia
//
//  Dependency Injection Container for services
//

import Foundation

/// Dependency injection container that holds all service instances
/// Provides a clean way to swap between Mock and Live implementations
final class AppContainer {
    
    /// Gym-related services (fetch gyms, gym details)
    let gymService: GymServiceProtocol
    
    /// Booking-related services (create bookings)
    let bookingService: BookingServiceProtocol
    
    /// Profile-related services (fetch/update user profile)
    let profileService: ProfileServiceProtocol
    
    /// Notification-related services (permissions, scheduling)
    let notificationService: NotificationServiceProtocol
    
    /// Wallet-related services (balance, transactions, top-up)
    let walletService: WalletServiceProtocol
    
    /// Booking history services (fetch bookings, cancel)
    let bookingHistoryService: BookingHistoryServiceProtocol
    
    /// Check-in services (validate codes, mark checked-in)
    let checkInService: CheckInServiceProtocol
    
    /// Groups and chat services (fetch groups, send messages)
    let groupsChatService: GroupsChatServiceProtocol
    
    // MARK: - Initialization
    
    init(
        gymService: GymServiceProtocol,
        bookingService: BookingServiceProtocol,
        profileService: ProfileServiceProtocol,
        notificationService: NotificationServiceProtocol,
        walletService: WalletServiceProtocol,
        bookingHistoryService: BookingHistoryServiceProtocol,
        checkInService: CheckInServiceProtocol,
        groupsChatService: GroupsChatServiceProtocol
    ) {
        self.gymService = gymService
        self.bookingService = bookingService
        self.profileService = profileService
        self.notificationService = notificationService
        self.walletService = walletService
        self.bookingHistoryService = bookingHistoryService
        self.checkInService = checkInService
        self.groupsChatService = groupsChatService
    }
    
    // MARK: - Factory Methods
    
    /// Creates a container configured for demo/development mode
    /// Uses mock services that return realistic fake data
    static func demo() -> AppContainer {
        // Ensure MockBookingStore is seeded
        MockBookingStore.shared.seedIfNeeded()
        
        let gymService = MockGymService()
        let bookingService = MockBookingService(gymService: gymService)
        let profileService = MockProfileService()
        let notificationService = MockNotificationService()
        let walletService = MockWalletService()
        let bookingHistoryService = MockBookingHistoryService()
        let checkInService = MockCheckInService()
        let groupsChatService = MockGroupsChatService()
        
        return AppContainer(
            gymService: gymService,
            bookingService: bookingService,
            profileService: profileService,
            notificationService: notificationService,
            walletService: walletService,
            bookingHistoryService: bookingHistoryService,
            checkInService: checkInService,
            groupsChatService: groupsChatService
        )
    }
    
    /// Creates a container configured for live/production mode
    /// Uses real iOS notification system
    static func live() -> AppContainer {
        // Ensure MockBookingStore is seeded
        MockBookingStore.shared.seedIfNeeded()
        
        let gymService = MockGymService() // TODO: Replace with real API service
        let bookingService = MockBookingService(gymService: gymService)
        let profileService = MockProfileService()
        let notificationService = LocalNotificationService() // Real iOS notifications
        let walletService = MockWalletService() // TODO: Replace with real wallet service
        let bookingHistoryService = MockBookingHistoryService() // TODO: Replace with real service
        let checkInService = MockCheckInService() // TODO: Replace with real check-in service
        let groupsChatService = MockGroupsChatService() // Uses mock for offline operation
        
        return AppContainer(
            gymService: gymService,
            bookingService: bookingService,
            profileService: profileService,
            notificationService: notificationService,
            walletService: walletService,
            bookingHistoryService: bookingHistoryService,
            checkInService: checkInService,
            groupsChatService: groupsChatService
        )
    }
}

