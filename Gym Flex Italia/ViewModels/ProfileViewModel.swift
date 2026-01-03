//
//  ProfileViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for user profile management.
//  Uses canonical stores and DI via AppContainer.
//

import Foundation
import Combine

/// ViewModel for user profile management
@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Wallet balance from WalletStore (canonical source)
    @Published var walletBalanceCents: Int?
    
    /// Booking statistics from MockBookingStore (canonical source)
    @Published var activeCount: Int = 0
    @Published var pastCount: Int = 0
    @Published var lastBookingSummary: String?
    
    // MARK: - Legacy Support (for sections still using these)
    
    @Published var stats: WorkoutStats?
    @Published var recentBookings: [Booking] = []
    @Published var selectedGoals: Set<FitnessGoal> = []
    @Published var selectedAvatarStyle: AvatarStyle = .warrior
    @Published var isSaving = false
    @Published var successMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Observe WalletStore changes
        WalletStore.shared.$balanceCents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cents in
                self?.walletBalanceCents = cents
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Profile (DI via AppContainer)
    
    /// Load profile and related data using AppContainer services
    func load(using container: AppContainer) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch profile from profileService
            profile = try await container.profileService.fetchCurrentProfile()
            
            // Set up avatar/goals from profile
            selectedGoals = Set(profile?.fitnessGoals ?? [])
            selectedAvatarStyle = profile?.avatarStyle ?? .warrior
            
            // Load wallet balance from canonical WalletStore
            walletBalanceCents = WalletStore.shared.balanceCents
            
            // Load booking statistics from booking history service (matches Booking History screen)
            await loadBookingStatistics(using: container.bookingHistoryService)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Retry loading after error
    func retry(using container: AppContainer) async {
        await load(using: container)
    }
    
    /// Refresh data (pull-to-refresh)
    func refresh(using container: AppContainer) async {
        await load(using: container)
    }
    
    /// Legacy refresh method (for backward compatibility)
    func refresh() async {
        // Refresh booking statistics from store (fallback to local store)
        loadBookingStatisticsFromStore()
        
        // Refresh wallet balance
        walletBalanceCents = WalletStore.shared.balanceCents
    }
    
    // MARK: - Booking Statistics (matches Booking History screen logic)
    
    /// Load booking statistics from booking history service
    /// Uses same data source and logic as BookingHistoryViewModel
    private func loadBookingStatistics(using service: BookingHistoryServiceProtocol) async {
        let now = Date()
        
        do {
            let bookings = try await service.fetchBookings()
            
            // Active: current session if exists (not cancelled, endTime > now)
            let store = MockBookingStore.shared
            activeCount = (store.currentUserSession() != nil) ? 1 : 0
            
            // Past: same logic as BookingHistoryViewModel.pastBookings
            // (cancelled, completed, or endTime <= now)
            pastCount = bookings.filter { booking in
                booking.status == .cancelled || booking.status == .completed || booking.endTime <= now
            }.count
            
            // Last booking summary: most recent booking
            if let lastBooking = bookings.sorted(by: { $0.startTime > $1.startTime }).first {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                let dateString = dateFormatter.string(from: lastBooking.startTime)
                lastBookingSummary = "\(lastBooking.gymName ?? "Gym") • \(dateString)"
            } else {
                lastBookingSummary = nil
            }
            
            #if DEBUG
            print("👤 ProfileViewModel.loadBookingStatistics: active=\(activeCount), past=\(pastCount) (from service)")
            #endif
            
        } catch {
            // Fallback to local store on error
            loadBookingStatisticsFromStore()
        }
    }
    
    /// Fallback: Load booking statistics from local store
    private func loadBookingStatisticsFromStore() {
        let store = MockBookingStore.shared
        let now = Date()
        
        // Get ALL bookings (including seeded) from the store
        let allBookings = store.allBookings()
        
        // Active: current session if exists (0 or 1)
        activeCount = (store.currentUserSession() != nil) ? 1 : 0
        
        // Past: same logic as BookingHistoryViewModel.pastBookings
        pastCount = allBookings.filter { booking in
            booking.status == .cancelled || booking.status == .completed || booking.endTime <= now
        }.count
        
        // Last booking summary: most recent booking
        if let lastBooking = allBookings.sorted(by: { $0.startTime > $1.startTime }).first {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dateString = dateFormatter.string(from: lastBooking.startTime)
            lastBookingSummary = "\(lastBooking.gymName ?? "Gym") • \(dateString)"
        } else {
            lastBookingSummary = nil
        }
        
        #if DEBUG
        print("👤 ProfileViewModel.loadBookingStatisticsFromStore: active=\(activeCount), past=\(pastCount) (from store)")
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// Formatted wallet balance string
    var formattedWalletBalance: String {
        guard let cents = walletBalanceCents else { return "€0.00" }
        return String(format: "€%.2f", Double(cents) / 100.0)
    }
    
    /// Whether user has any bookings
    var hasBookings: Bool {
        activeCount > 0 || pastCount > 0
    }
    
    // MARK: - Legacy Methods (for sections still using them)
    
    /// Avatar progression info
    var avatarProgression: AvatarProgression? {
        guard let profile = profile else { return nil }
        
        return AvatarProgression(
            currentLevel: profile.avatarLevel,
            totalWorkouts: profile.totalWorkouts,
            currentStreak: profile.currentStreak,
            style: profile.avatarStyle
        )
    }
    
    var totalWorkoutTime: String {
        guard let stats = stats else { return "0h" }
        let hours = stats.totalMinutes / 60
        let minutes = stats.totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var averageWorkoutsPerWeek: Double {
        guard let stats = stats else { return 0 }
        return Double(stats.weeklyWorkouts)
    }
    
    // MARK: - Goal Management
    
    func toggleGoal(_ goal: FitnessGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
}
