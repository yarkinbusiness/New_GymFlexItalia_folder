//
//  MockBookingStore.swift
//  Gym Flex Italia
//
//  Shared in-memory booking store for consistent state across mock services.
//  This is the single source of truth for bookings during a session.
//

import Foundation

/// Shared booking store that maintains consistent state across all mock services.
/// Used by MockBookingHistoryService, MockBookingService, and MockCheckInService.
final class MockBookingStore {
    
    // MARK: - Singleton
    
    static let shared = MockBookingStore()
    
    // MARK: - State
    
    /// All bookings in the store
    private(set) var bookings: [Booking] = []
    
    /// Whether initial seed data has been loaded
    private var hasSeeded = false
    
    private init() {}
    
    // MARK: - Seeding
    
    /// Seeds initial mock bookings if not already seeded.
    /// Will NOT overwrite if user-created bookings exist.
    /// Call this from services that need initial data.
    func seedIfNeeded() {
        guard !hasSeeded else { return }
        
        // Check if there are any user-created bookings (booking_GF- prefix)
        let hasUserBookings = bookings.contains { $0.id.hasPrefix("booking_GF-") }
        if hasUserBookings {
            print("🛡️ MockBookingStore.seedIfNeeded: Skipping seed - user bookings already exist")
            hasSeeded = true
            return
        }
        
        hasSeeded = true
        bookings = Self.generateSeedBookings()
        print("🌱 MockBookingStore.seedIfNeeded: Seeded \(bookings.count) initial bookings")
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
        
        // Debug: Print current store contents
        print("📊 MockBookingStore: Total bookings=\(bookings.count), Upcoming=\(upcomingBookings().count)")
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
            "\(booking.id) | \(booking.gymName ?? "nil") | \(booking.status) | start=\(booking.startTime) | end=\(booking.endTime) | dur=\(booking.duration)min"
        }
        return "MockBookingStore (\(bookings.count) bookings):\n" + lines.joined(separator: "\n")
    }
    
    /// Resets the store to unseeded state (for testing)
    func reset() {
        bookings = []
        hasSeeded = false
        print("🔄 MockBookingStore.reset: Store cleared")
    }
    
    // MARK: - Seed Data Generation
    
    /// Generates initial seed bookings using canonical gym data
    private static func generateSeedBookings() -> [Booking] {
        let calendar = Calendar.current
        let now = Date()
        var bookings: [Booking] = []
        
        let dataStore = MockDataStore.shared
        let userId = MockDataStore.mockUserId
        let gyms = dataStore.gyms
        
        // === 3 UPCOMING BOOKINGS ===
        
        // Tomorrow morning - Gym 1
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        let gym1 = gyms[0] // gym_1: FitRoma Center
        bookings.append(Booking(
            id: "booking_upcoming_001",
            userId: userId,
            gymId: gym1.id,
            gymName: gym1.name,
            gymAddress: gym1.address,
            gymCoverImageURL: gym1.coverImageURL,
            startTime: tomorrowMorning,
            endTime: calendar.date(byAdding: .hour, value: 1, to: tomorrowMorning)!,
            duration: 60,
            pricePerHour: gym1.pricePerHour,
            totalPrice: gym1.pricePerHour,
            currency: "EUR",
            status: .confirmed,
            checkinCode: MockDataStore.makeCheckinCode(),
            checkinTime: nil,
            checkoutTime: nil,
            qrCodeData: "qr_booking_upcoming_001",
            qrCodeExpiresAt: tomorrowMorning,
            createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
            updatedAt: calendar.date(byAdding: .day, value: -1, to: now)!,
            cancelledAt: nil,
            cancellationReason: nil
        ))
        
        // Day after tomorrow afternoon - Gym 2
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: now)!
        let dayAfterAfternoon = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: dayAfter)!
        let gym2 = gyms[1] // gym_2: Colosseo Fitness Lab
        bookings.append(Booking(
            id: "booking_upcoming_002",
            userId: userId,
            gymId: gym2.id,
            gymName: gym2.name,
            gymAddress: gym2.address,
            gymCoverImageURL: gym2.coverImageURL,
            startTime: dayAfterAfternoon,
            endTime: calendar.date(byAdding: .minute, value: 90, to: dayAfterAfternoon)!,
            duration: 90,
            pricePerHour: gym2.pricePerHour,
            totalPrice: gym2.pricePerHour * 1.5,
            currency: "EUR",
            status: .confirmed,
            checkinCode: MockDataStore.makeCheckinCode(),
            checkinTime: nil,
            checkoutTime: nil,
            qrCodeData: "qr_booking_upcoming_002",
            qrCodeExpiresAt: dayAfterAfternoon,
            createdAt: calendar.date(byAdding: .day, value: -2, to: now)!,
            updatedAt: calendar.date(byAdding: .day, value: -2, to: now)!,
            cancelledAt: nil,
            cancellationReason: nil
        ))
        
        // Next week (with "fail" in ID for testing deterministic failure) - Gym 3
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now)!
        let nextWeekEvening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: nextWeek)!
        let gym3 = gyms[2] // gym_3: Trastevere Active Hub
        bookings.append(Booking(
            id: "booking_upcoming_fail_003",
            userId: userId,
            gymId: gym3.id,
            gymName: gym3.name,
            gymAddress: gym3.address,
            gymCoverImageURL: gym3.coverImageURL,
            startTime: nextWeekEvening,
            endTime: calendar.date(byAdding: .hour, value: 2, to: nextWeekEvening)!,
            duration: 120,
            pricePerHour: gym3.pricePerHour,
            totalPrice: gym3.pricePerHour * 2,
            currency: "EUR",
            status: .confirmed,
            checkinCode: MockDataStore.makeCheckinCode(),
            checkinTime: nil,
            checkoutTime: nil,
            qrCodeData: "qr_booking_upcoming_003",
            qrCodeExpiresAt: nextWeekEvening,
            createdAt: calendar.date(byAdding: .day, value: -3, to: now)!,
            updatedAt: calendar.date(byAdding: .day, value: -3, to: now)!,
            cancelledAt: nil,
            cancellationReason: nil
        ))
        
        // === 8 PAST/COMPLETED BOOKINGS ===
        
        for i in 0..<8 {
            let daysAgo = i + 2 // Start from 2 days ago
            let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let hour = 8 + (i * 2) % 12 // Vary the time
            let pastTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: pastDate)!
            let gym = gyms[i % gyms.count]
            let duration = [60, 90, 60, 120, 60, 90, 60, 120][i]
            
            bookings.append(Booking(
                id: "booking_completed_\(String(format: "%03d", i + 1))",
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
                checkinCode: MockDataStore.makeCheckinCode(),
                checkinTime: pastTime,
                checkoutTime: calendar.date(byAdding: .minute, value: duration, to: pastTime)!,
                qrCodeData: nil,
                qrCodeExpiresAt: nil,
                createdAt: calendar.date(byAdding: .day, value: -daysAgo - 1, to: now)!,
                updatedAt: calendar.date(byAdding: .minute, value: duration, to: pastTime)!,
                cancelledAt: nil,
                cancellationReason: nil
            ))
        }
        
        // === 1 CANCELLED BOOKING ===
        
        let cancelledDate = calendar.date(byAdding: .day, value: -5, to: now)!
        let cancelledTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: cancelledDate)!
        let cancelledGym = gyms[4] // gym_5: Vatican City Fitness
        bookings.append(Booking(
            id: "booking_cancelled_001",
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
            checkinCode: nil,
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
