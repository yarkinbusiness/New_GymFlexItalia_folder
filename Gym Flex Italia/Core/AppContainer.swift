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
    
    // MARK: - Network Infrastructure
    
    /// API environment configuration
    let environment: APIEnvironment
    
    /// Network client for API calls
    let networkClient: NetworkClient
    
    // MARK: - Feature Flags
    
    /// Whether to use live services instead of mocks
    /// Set to false to keep demo behavior; true enables real API calls
    /// IMPORTANT: Only set to true when backend is ready
    var useLiveServices: Bool = false
    
    // MARK: - Services
    
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
        environment: APIEnvironment,
        networkClient: NetworkClient,
        useLiveServices: Bool = false,
        gymService: GymServiceProtocol,
        bookingService: BookingServiceProtocol,
        profileService: ProfileServiceProtocol,
        notificationService: NotificationServiceProtocol,
        walletService: WalletServiceProtocol,
        bookingHistoryService: BookingHistoryServiceProtocol,
        checkInService: CheckInServiceProtocol,
        groupsChatService: GroupsChatServiceProtocol
    ) {
        self.environment = environment
        self.networkClient = networkClient
        self.useLiveServices = useLiveServices
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
    /// Network client is configured but not used (mocks handle all data)
    static func demo() -> AppContainer {
        // Ensure MockBookingStore is seeded
        MockBookingStore.shared.seedIfNeeded()
        
        // Demo environment - network client exists but won't be called
        let environment = APIEnvironment.demo()
        let networkClient = URLSessionNetworkClient(environment: environment)
        
        // All mock services - no network calls in demo mode
        let gymService = MockGymService()
        let bookingService = MockBookingService(gymService: gymService)
        let profileService = MockProfileService()
        let notificationService = MockNotificationService()
        let walletService = MockWalletService()
        let bookingHistoryService = MockBookingHistoryService()
        let checkInService = MockCheckInService()
        let groupsChatService = MockGroupsChatService()
        
        return AppContainer(
            environment: environment,
            networkClient: networkClient,
            useLiveServices: false,  // Demo always uses mocks
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
    /// Can use either mock or live services based on feature flag
    /// - Parameter useLiveServices: Whether to use real API services (default: false for safety)
    static func live(useLiveServices: Bool = false) -> AppContainer {
        // Ensure MockBookingStore is seeded (needed even if using live services as fallback)
        MockBookingStore.shared.seedIfNeeded()
        
        // Live environment
        let environment = APIEnvironment.live()
        let networkClient = URLSessionNetworkClient(environment: environment)
        
        // Choose services based on feature flag
        let gymService: GymServiceProtocol
        let bookingService: BookingServiceProtocol
        let profileService: ProfileServiceProtocol
        let bookingHistoryService: BookingHistoryServiceProtocol
        
        if useLiveServices {
            // Live services - real API calls
            gymService = LiveGymService(networkClient: networkClient)
            bookingService = LiveBookingService(networkClient: networkClient)
            profileService = LiveProfileService(networkClient: networkClient)
            bookingHistoryService = LiveBookingHistoryService(networkClient: networkClient)
        } else {
            // Safe default - use mocks even in "live" config
            let mockGymService = MockGymService()
            gymService = mockGymService
            bookingService = MockBookingService(gymService: mockGymService)
            profileService = MockProfileService()
            bookingHistoryService = MockBookingHistoryService()
        }
        
        // These always use mock/local implementations for now
        let notificationService = LocalNotificationService() // Real iOS notifications
        let walletService = MockWalletService()
        let checkInService = MockCheckInService()
        let groupsChatService = MockGroupsChatService()
        
        return AppContainer(
            environment: environment,
            networkClient: networkClient,
            useLiveServices: useLiveServices,
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
