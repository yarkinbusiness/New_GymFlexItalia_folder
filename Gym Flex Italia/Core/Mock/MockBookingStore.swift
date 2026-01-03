//
//  MockBookingStore.swift
//  Gym Flex Italia
//
//  Shared persisted booking store for consistent state across mock services.
//  This is the single source of truth for bookings.
//  Persisted to UserDefaults for data retention across app launches.
//

import Foundation

/// Persisted booking data structure
struct PersistedBookingData: Codable {
    var bookings: [Booking]
    
    static let empty = PersistedBookingData(bookings: [])
}

/// Errors that can occur when extending a booking
enum BookingExtensionError: LocalizedError {
    case bookingNotFound
    case notUserBooking
    case bookingCancelled
    case sessionEnded
    case insufficientFunds
    
    var errorDescription: String? {
        switch self {
        case .bookingNotFound:
            return "Booking not found"
        case .notUserBooking:
            return "Cannot extend this booking"
        case .bookingCancelled:
            return "Cannot extend a cancelled booking"
        case .sessionEnded:
            return "Session has already ended"
        case .insufficientFunds:
            return "Insufficient balance to extend session"
        }
    }
}

/// Shared booking store that maintains consistent state across all mock services.
/// Used by MockBookingHistoryService, MockBookingService, and MockCheckInService.
/// Persists to UserDefaults for data retention across app launches.
final class MockBookingStore {
    
    // MARK: - Singleton
    
    static let shared = MockBookingStore()
    
    // MARK: - Persistence Keys
    
    private static let persistenceKey = "booking_store_v1"
    
    // MARK: - State
    
    /// All bookings in the store
    private(set) var bookings: [Booking] = []
    
    /// Whether initial seed data has been loaded
    private var hasSeeded = false
    
    private init() {
        load()
        print("📚 MockBookingStore.init: Loaded \(bookings.count) bookings from storage")
    }
    
    // MARK: - Persistence
    
    /// Load booking data from UserDefaults
    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else {
            print("📚 MockBookingStore.load: No persisted data")
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(PersistedBookingData.self, from: data)
            bookings = decoded.bookings
            print("📚 MockBookingStore.load: Loaded \(bookings.count) bookings")
        } catch {
            print("⚠️ MockBookingStore.load: Failed to decode: \(error)")
        }
    }
    
    /// Save booking data to UserDefaults
    func save() {
        let data = PersistedBookingData(bookings: bookings)
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: Self.persistenceKey)
            print("📚 MockBookingStore.save: Saved \(bookings.count) bookings")
        } catch {
            print("⚠️ MockBookingStore.save: Failed to encode: \(error)")
        }
    }
    
    // MARK: - User Booking Detection
    
    /// Determines if a booking is a user-created booking (not seeded demo data)
    /// User bookings have IDs starting with "booking_GF-" (created via MockBookingService)
    func isUserBooking(_ booking: Booking) -> Bool {
        return booking.id.hasPrefix("booking_GF-")
    }
    
    /// Whether any user-created bookings exist in the store
    var hasUserBookings: Bool {
        bookings.contains(where: isUserBooking)
    }
    
    /// Returns only user-created bookings (not seeded demo data)
    func userBookings() -> [Booking] {
        bookings.filter { isUserBooking($0) }
    }
    
    // MARK: - Current Session Selection (SHARED LOGIC)
    
    /// Returns the current active user session.
    /// This is THE shared selection rule used by BOTH Home and Check-in tabs.
    ///
    /// Selection rules:
    /// - ONLY considers user bookings (isUserBooking == true)
    /// - Excludes cancelled bookings
    /// - Session end time must be > now (not yet ended)
    /// - Returns the booking with the earliest endTime (currently running or soonest ending)
    ///
    /// Returns nil if user has not booked any sessions or all sessions have ended.
    func currentUserSession(now: Date = Date()) -> Booking? {
        let activeSessions = bookings
            .filter { isUserBooking($0) }          // Only user bookings
            .filter { $0.status != .cancelled }     // Not cancelled
            .filter { $0.endTime > now }            // Not ended yet
            .sorted { $0.endTime < $1.endTime }     // Sort by endTime ascending
        
        let session = activeSessions.first // Earliest ending session
        
        print("📚 MockBookingStore.currentUserSession: \(session?.id ?? "nil") (checked \(activeSessions.count) active user sessions)")
        return session
    }
    
    /// Returns the next upcoming user booking (not yet started).
    /// Useful for "upcoming next" displays.
    func nextUserSession(now: Date = Date()) -> Booking? {
        let upcoming = bookings
            .filter { isUserBooking($0) }           // Only user bookings
            .filter { $0.status != .cancelled }     // Not cancelled
            .filter { $0.startTime > now }          // Not yet started
            .sorted { $0.startTime < $1.startTime } // Sort by startTime ascending
        
        return upcoming.first
    }
    
    /// Returns the most recent user booking (for Quick Book display)
    /// - Returns the user booking with the most recent startTime
    func lastUserBooking() -> Booking? {
        return userBookings()
            .sorted { $0.startTime > $1.startTime }
            .first
    }
    
    /// Whether user has an active session (for single active session rule)
    func hasActiveSession(now: Date = Date()) -> Bool {
        return currentUserSession(now: now) != nil
    }
    
    // MARK: - Session State Helpers (Single Source of Truth)
    
    /// Check if a session is currently active (not cancelled, not ended)
    /// - Parameters:
    ///   - booking: The booking to check
    ///   - now: Current date (defaults to Date())
    /// - Returns: true if session is active and not yet ended
    func isSessionActive(_ booking: Booking, now: Date = Date()) -> Bool {
        return booking.status != .cancelled && booking.endTime > now
    }
    
    /// Check if a session has ended (time expired, not cancelled)
    /// - Parameters:
    ///   - booking: The booking to check
    ///   - now: Current date (defaults to Date())
    /// - Returns: true if session time has expired
    func isSessionEnded(_ booking: Booking, now: Date = Date()) -> Bool {
        return booking.status != .cancelled && booking.endTime <= now
    }
    
    /// Check if a session was cancelled
    /// - Parameter booking: The booking to check
    /// - Returns: true if booking status is cancelled
    func isSessionCancelled(_ booking: Booking) -> Bool {
        return booking.status == .cancelled
    }
    
    // MARK: - Session Extension
    
    /// Extends a booking by adding minutes to its duration.
    /// - Parameters:
    ///   - bookingId: The booking ID to extend
    ///   - addMinutes: Minutes to add (e.g., 30, 60, 90)
    /// - Returns: The updated booking
    /// - Throws: If booking doesn't exist, is not active, or is cancelled
    func extend(bookingId: String, addMinutes: Int) throws -> Booking {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else {
            throw BookingExtensionError.bookingNotFound
        }
        
        var booking = bookings[index]
        
        // Must be an active session
        guard isUserBooking(booking) else {
            throw BookingExtensionError.notUserBooking
        }
        
        guard booking.status != .cancelled else {
            throw BookingExtensionError.bookingCancelled
        }
        
        let now = Date()
        guard booking.endTime > now else {
            throw BookingExtensionError.sessionEnded
        }
        
        // Update duration and end time
        let oldDuration = booking.duration
        let oldEndTime = booking.endTime
        
        booking.duration += addMinutes
        booking.endTime = Calendar.current.date(byAdding: .minute, value: addMinutes, to: booking.endTime) ?? booking.endTime
        booking.updatedAt = Date()
        
        // Update in store
        bookings[index] = booking
        save()
        
        print("⏱️ MockBookingStore.extend: bookingId=\(bookingId) +\(addMinutes)min, duration \(oldDuration)→\(booking.duration), endTime \(oldEndTime)→\(booking.endTime)")
        
        return booking
    }
    
    // MARK: - Seeding
    
    /// Seeds initial demo bookings if not already seeded.
    /// Will NOT overwrite if any bookings exist in storage.
    /// 
    /// IMPORTANT: Seeds ONLY past/completed/cancelled bookings.
    /// Does NOT seed any upcoming bookings - this ensures fresh app shows no active session.
    func seedIfNeeded() {
        guard !hasSeeded else { return }
        
        // If we already have bookings (from persistence), don't overwrite
        if !bookings.isEmpty {
            print("🛡️ MockBookingStore.seedIfNeeded: Skipping seed - \(bookings.count) bookings already exist")
            hasSeeded = true
            return
        }
        
        hasSeeded = true
        bookings = Self.generateSeedBookings()
        save()
        print("🌱 MockBookingStore.seedIfNeeded: Seeded \(bookings.count) initial bookings (all past/completed)")
    }
    
    // MARK: - Query Methods
    
    /// Returns all bookings, optionally sorted by start time (most recent first)
    func allBookings() -> [Booking] {
        bookings.sorted { $0.startTime > $1.startTime }
    }
    
    /// Returns upcoming bookings that haven't ended yet (endTime > now)
    /// Includes bookings in progress (started but not ended)
    func upcomingBookings() -> [Booking] {
        let now = Date()
        return bookings
            .filter { booking in
                // Not cancelled
                guard booking.status != .cancelled else { return false }
                
                // Session hasn't ended yet (endTime > now)
                return booking.endTime > now
            }
            .sorted { $0.startTime < $1.startTime }
    }
    
    /// Returns upcoming USER bookings only (excludes seed bookings)
    func upcomingUserBookings() -> [Booking] {
        let now = Date()
        return bookings
            .filter { isUserBooking($0) }
            .filter { $0.status != .cancelled }
            .filter { $0.endTime > now }
            .sorted { $0.startTime < $1.startTime }
    }
    
    /// Returns the next upcoming booking (soonest booking that hasn't ended)
    func nextUpcomingBooking() -> Booking? {
        upcomingBookings().first
    }
    
    /// Find a booking by its ID
    func bookingById(_ id: String) -> Booking? {
        bookings.first { $0.id == id }
    }
    
    // MARK: - Mutation Methods
    
    /// Insert or update a booking in the store
    func upsert(_ booking: Booking) {
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index] = booking
            print("📝 MockBookingStore.upsert: UPDATED bookingId=\(booking.id) gymId=\(booking.gymId) gymName=\(booking.gymName ?? "nil") startAt=\(booking.startTime) duration=\(booking.duration) status=\(booking.status)")
        } else {
            bookings.append(booking)
            print("✅ MockBookingStore.upsert: INSERTED bookingId=\(booking.id) gymId=\(booking.gymId) gymName=\(booking.gymName ?? "nil") startAt=\(booking.startTime) duration=\(booking.duration) status=\(booking.status)")
        }
        
        // Persist changes
        save()
        
        // Debug: Print current store contents
        print("📊 MockBookingStore: Total bookings=\(bookings.count), Upcoming=\(upcomingBookings().count), UserBookings=\(userBookings().count)")
    }
    
    /// Marks a booking as checked in and returns the updated booking
    @discardableResult
    func markCheckedIn(bookingId: String, checkedInAt: Date) -> Booking? {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return nil
        }
        
        var updatedBooking = bookings[index]
        updatedBooking.status = .checkedIn
        updatedBooking.checkinTime = checkedInAt
        updatedBooking.updatedAt = Date()
        
        bookings[index] = updatedBooking
        save()
        print("✅ MockBookingStore.markCheckedIn: bookingId=\(bookingId)")
        return updatedBooking
    }
    
    /// Cancels a booking and returns the updated booking
    @discardableResult
    func cancel(bookingId: String) -> Booking? {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return nil
        }
        
        var updatedBooking = bookings[index]
        updatedBooking.status = .cancelled
        updatedBooking.cancelledAt = Date()
        updatedBooking.updatedAt = Date()
        
        bookings[index] = updatedBooking
        save()
        
        // LEDGER INVARIANT 4: Cancel does NOT create a refund
        // Product rule: no refunds - wallet balance remains unchanged
        print("🚫 CANCEL: no refund policy enforced bookingId=\(bookingId)")
        print("❌ MockBookingStore.cancel: bookingId=\(bookingId)")
        return updatedBooking
    }
    
    // MARK: - Debug Helpers
    
    /// Debug dump of all bookings for console logging
    func debugDump() -> String {
        if bookings.isEmpty {
            return "MockBookingStore: EMPTY"
        }
        let lines = bookings.map { booking in
            let isUser = isUserBooking(booking) ? "👤" : "🌱"
            return "\(isUser) \(booking.id) | \(booking.gymName ?? "nil") | \(booking.status) | start=\(booking.startTime) | end=\(booking.endTime) | dur=\(booking.duration)min"
        }
        return "MockBookingStore (\(bookings.count) bookings, \(userBookings().count) user bookings):\n" + lines.joined(separator: "\n")
    }
    
    /// Resets the store to unseeded state (for testing)
    func reset() {
        bookings = []
        hasSeeded = false
        save()
        print("🔄 MockBookingStore.reset: Store cleared")
    }
    
    // MARK: - Seed Data Generation
    
    /// Generates initial seed bookings using canonical gym data.
    /// 
    /// IMPORTANT: Seeds ONLY past/completed/cancelled bookings.
    /// NO upcoming bookings are seeded - this ensures fresh app has no active session.
    /// Seed bookings do NOT have checkInCode (only user bookings get codes).
    private static func generateSeedBookings() -> [Booking] {
        let calendar = Calendar.current
        let now = Date()
        var bookings: [Booking] = []
        
        let dataStore = MockDataStore.shared
        let userId = MockDataStore.mockUserId
        let gyms = dataStore.gyms
        
        // === ONLY PAST/COMPLETED BOOKINGS (no upcoming!) ===
        // This ensures: fresh app with no user bookings => no Active Session
        
        for i in 0..<8 {
            let daysAgo = i + 2 // Start from 2 days ago
            let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let hour = 8 + (i * 2) % 12 // Vary the time
            let pastTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: pastDate)!
            let gym = gyms[i % gyms.count]
            let duration = [60, 90, 60, 120, 60, 90, 60, 120][i]
            
            bookings.append(Booking(
                id: "booking_seed_completed_\(String(format: "%03d", i + 1))",
                userId: userId,
                gymId: gym.id,
                gymName: gym.name,
                gymAddress: gym.address,
                gymCoverImageURL: gym.coverImageURL,
                startTime: pastTime,
                endTime: calendar.date(byAdding: .minute, value: duration, to: pastTime)!,
                duration: duration,
                pricePerHour: gym.pricePerHour,
                totalPrice: gym.pricePerHour * Double(duration) / 60.0,
                currency: "EUR",
                status: .completed,
                checkinCode: nil,  // NO check-in code for seed bookings
                checkinTime: pastTime,
                checkoutTime: calendar.date(byAdding: .minute, value: duration, to: pastTime)!,
                qrCodeData: nil,   // NO QR data for seed bookings
                qrCodeExpiresAt: nil,
                createdAt: calendar.date(byAdding: .day, value: -daysAgo - 1, to: now)!,
                updatedAt: calendar.date(byAdding: .minute, value: duration, to: pastTime)!,
                cancelledAt: nil,
                cancellationReason: nil
            ))
        }
        
        // === 1 CANCELLED BOOKING (past, not upcoming) ===
        
        let cancelledDate = calendar.date(byAdding: .day, value: -5, to: now)!
        let cancelledTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: cancelledDate)!
        let cancelledGym = gyms[4] // gym_5: Vatican City Fitness
        bookings.append(Booking(
            id: "booking_seed_cancelled_001",
            userId: userId,
            gymId: cancelledGym.id,
            gymName: cancelledGym.name,
            gymAddress: cancelledGym.address,
            gymCoverImageURL: cancelledGym.coverImageURL,
            startTime: cancelledTime,
            endTime: calendar.date(byAdding: .hour, value: 1, to: cancelledTime)!,
            duration: 60,
            pricePerHour: cancelledGym.pricePerHour,
            totalPrice: cancelledGym.pricePerHour,
            currency: "EUR",
            status: .cancelled,
            checkinCode: nil,  // NO check-in code for seed bookings
            checkinTime: nil,
            checkoutTime: nil,
            qrCodeData: nil,
            qrCodeExpiresAt: nil,
            createdAt: calendar.date(byAdding: .day, value: -6, to: now)!,
            updatedAt: calendar.date(byAdding: .day, value: -5, to: now)!,
            cancelledAt: calendar.date(byAdding: .day, value: -5, to: now)!,
            cancellationReason: "User requested cancellation"
        ))
        
        return bookings
    }
}
