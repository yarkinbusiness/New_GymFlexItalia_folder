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
    @Published var upcomingCount: Int = 0
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
            
            // Load booking statistics from canonical MockBookingStore
            loadBookingStatistics()
            
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
        // Refresh booking statistics from store
        loadBookingStatistics()
        
        // Refresh wallet balance
        walletBalanceCents = WalletStore.shared.balanceCents
    }
    
    // MARK: - Booking Statistics (from canonical MockBookingStore)
    
    private func loadBookingStatistics() {
        let store = MockBookingStore.shared
        let now = Date()
        
        // Only count USER bookings (not seeded demo data)
        let userBookings = store.userBookings()
        
        // Upcoming: endTime > now AND not cancelled
        upcomingCount = userBookings.filter { booking in
            booking.status != .cancelled && booking.endTime > now
        }.count
        
        // Past: endTime <= now OR status is completed/cancelled
        pastCount = userBookings.filter { booking in
            booking.endTime <= now || booking.status == .completed || booking.status == .cancelled
        }.count
        
        // Last booking summary: most recent user booking
        if let lastBooking = store.lastUserBooking() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dateString = dateFormatter.string(from: lastBooking.startTime)
            lastBookingSummary = "\(lastBooking.gymName) • \(dateString)"
        } else {
            lastBookingSummary = nil
        }
        
        print("👤 ProfileViewModel.loadBookingStatistics: upcoming=\(upcomingCount), past=\(pastCount)")
    }
    
    // MARK: - Computed Properties
    
    /// Formatted wallet balance string
    var formattedWalletBalance: String {
        guard let cents = walletBalanceCents else { return "€0.00" }
        return String(format: "€%.2f", Double(cents) / 100.0)
    }
    
    /// Whether user has any bookings
    var hasBookings: Bool {
        upcomingCount > 0 || pastCount > 0
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
