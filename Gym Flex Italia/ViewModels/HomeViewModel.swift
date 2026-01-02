//
//  HomeViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for the Home/Dashboard tab.
//  Reads from canonical data stores: MockDataStore.gyms, MockBookingStore.
//  Uses LocationService for nearby gyms calculation.
//
//  IMPORTANT: Uses MockBookingStore.currentUserSession() for active session detection.
//  This ensures Home and Check-in tabs show the SAME booking.
//

import Foundation
import CoreLocation
import Combine

/// ViewModel for the Home tab - uses canonical data stores only
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Nearby gyms sorted by distance (top 3)
    @Published var nearbyGyms: [Gym] = []
    
    /// All bookings sorted by startTime desc (for Recent Activity)
    @Published var recentBookings: [Booking] = []
    
    /// Most recent USER booking (for Quick Book display when no active session)
    @Published var lastUserBooking: Booking?
    
    /// Active USER session (from shared currentUserSession() logic)
    /// This is only set for USER bookings, not seed bookings.
    @Published var activeBooking: Booking?
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Whether location permission is granted
    @Published var locationPermissionGranted = false
    
    // MARK: - Computed Properties
    
    /// Whether to show Active Session card (user has an active booking)
    var showActiveSession: Bool {
        activeBooking != nil
    }
    
    /// Whether to show Quick Book section (no active user booking)
    var showQuickBook: Bool {
        activeBooking == nil
    }
    
    // MARK: - Quick Book Properties
    
    /// Gym for Quick Book (from last user booking)
    var quickBookGym: Gym? {
        guard let booking = lastUserBooking else { return nil }
        return MockDataStore.shared.gymById(booking.gymId)
    }
    
    /// Gym address for Quick Book subtitle
    var quickBookAddress: String {
        quickBookGym?.address ?? lastUserBooking?.gymAddress ?? ""
    }
    
    /// Relative date for Quick Book display
    var quickBookRelativeDate: String {
        guard let booking = lastUserBooking else { return "" }
        return formatRelativeDate(booking.startTime)
    }
    
    // MARK: - Cancel Active Session
    
    /// Cancel the active session (no refund)
    func cancelActiveSession() {
        guard let booking = activeBooking else { return }
        
        // Cancel in store (no refund)
        MockBookingStore.shared.cancel(bookingId: booking.id)
        
        // Reload to update UI
        load()
        
        #if DEBUG
        print("🏠 HomeViewModel.cancelActiveSession: Cancelled booking \(booking.id)")
        #endif
    }
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Initial load
        load()
    }
    
    // MARK: - Load Data
    
    /// Load bookings from MockBookingStore and compute derived properties
    func load() {
        let bookingStore = MockBookingStore.shared
        
        // Get all bookings sorted by startTime descending (for Recent Activity)
        let allBookings = bookingStore.allBookings()
        recentBookings = allBookings
        
        // IMPORTANT: Use shared currentUserSession() for active session
        // This is THE shared selection logic - same as Check-in tab uses
        activeBooking = bookingStore.currentUserSession()
        
        // Last USER booking (for Quick Book display when no active session)
        lastUserBooking = bookingStore.lastUserBooking()
        
        #if DEBUG
        print("🏠 HomeViewModel.load: \(allBookings.count) total bookings, activeBooking=\(activeBooking?.id ?? "nil"), lastUserBooking=\(lastUserBooking?.id ?? "nil")")
        print("🏠 HomeViewModel.load: showActiveSession=\(showActiveSession), showQuickBook=\(showQuickBook)")
        #endif
    }
    
    // MARK: - Nearby Gyms
    
    /// Refresh nearby gyms based on user location
    /// - Parameter userLocation: Current user location (nil if unavailable)
    func refreshNearbyGyms(userLocation: CLLocation?) {
        let allGyms = MockDataStore.shared.gyms
        
        if let location = userLocation {
            locationPermissionGranted = true
            
            // Sort by distance and take top 3
            let sorted = allGyms.sorted { gym1, gym2 in
                gym1.distance(from: location) < gym2.distance(from: location)
            }
            nearbyGyms = Array(sorted.prefix(3))
            
            #if DEBUG
            print("🏠 HomeViewModel.refreshNearbyGyms: \(nearbyGyms.count) nearby gyms (location available)")
            #endif
        } else {
            // No location - show first 3 gyms from catalog
            nearbyGyms = Array(allGyms.prefix(3))
            locationPermissionGranted = false
            
            #if DEBUG
            print("🏠 HomeViewModel.refreshNearbyGyms: \(nearbyGyms.count) gyms (no location)")
            #endif
        }
    }
    
    // MARK: - Formatting Helpers
    
    /// Summary of last USER booking for Quick Book section
    /// Returns: (gymName, relativeDate, priceString) or nil if no user booking
    func lastBookingSummary() -> (gymName: String, relativeDate: String, priceString: String)? {
        guard let booking = lastUserBooking else { return nil }
        
        let gymName = booking.gymName ?? "Unknown Gym"
        let relativeDate = formatRelativeDate(booking.startTime)
        let priceString = formatPrice(booking)
        
        return (gymName, relativeDate, priceString)
    }
    
    /// Format a date as relative string ("Today", "Yesterday", "X days ago")
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: now)
            if let days = components.day, days > 0 {
                return "\(days) days ago"
            } else if let days = components.day, days < 0 {
                // Future date
                let futureDays = abs(days)
                if futureDays == 1 {
                    return "Tomorrow"
                } else {
                    return "In \(futureDays) days"
                }
            } else {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
    }
    
    /// Format booking price
    private func formatPrice(_ booking: Booking) -> String {
        // Use totalPrice from booking if available
        if booking.totalPrice > 0 {
            return String(format: "€%.2f", booking.totalPrice)
        }
        
        // Fallback: calculate from duration using PricingCalculator
        let gym = MockDataStore.shared.gymById(booking.gymId)
        let pricePerHour = gym?.pricePerHour ?? 2.0
        let totalCents = PricingCalculator.priceForBooking(durationMinutes: booking.duration, gymPricePerHour: pricePerHour)
        return PricingCalculator.formatCentsAsEUR(totalCents)
    }
    
    // MARK: - Distance Helper
    
    /// Calculate distance string for a gym
    func distanceString(for gym: Gym, from location: CLLocation?) -> String? {
        guard let location = location else { return nil }
        
        let distance = gym.distance(from: location)
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    // MARK: - Recent Activity
    
    /// Activity item for Recent Activity section
    struct RecentActivityItem: Identifiable {
        let id: String
        let booking: Booking
        let isOngoing: Bool
    }
    
    /// Get activity items for Recent Activity section
    /// - Active session first (if exists) with isOngoing=true
    /// - Then completed/past bookings (limited to last 4)
    func recentActivityItems() -> [RecentActivityItem] {
        var items: [RecentActivityItem] = []
        let now = Date()
        
        // 1. Active session at top (if exists)
        if let active = activeBooking {
            items.append(RecentActivityItem(
                id: active.id,
                booking: active,
                isOngoing: true
            ))
        }
        
        // 2. Completed/past bookings (exclude active session)
        let completedItems = recentBookings
            .filter { booking in
                // Past bookings (ended) or explicitly completed
                (booking.endTime < now || booking.status == .completed) &&
                // Exclude active session if it exists
                booking.id != activeBooking?.id
            }
            .sorted { $0.endTime > $1.endTime } // Most recent first
            .prefix(activeBooking != nil ? 3 : 4) // Show 3 if active, 4 if not
            .map { RecentActivityItem(id: $0.id, booking: $0, isOngoing: false) }
        
        items.append(contentsOf: completedItems)
        
        return items
    }
    
    /// Whether there are any activity items to show
    var hasRecentActivity: Bool {
        !recentActivityItems().isEmpty
    }
}
