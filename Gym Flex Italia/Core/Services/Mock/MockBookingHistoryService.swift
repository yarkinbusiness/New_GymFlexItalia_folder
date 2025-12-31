//
//  MockBookingHistoryService.swift
//  Gym Flex Italia
//
//  Mock implementation of BookingHistoryServiceProtocol for demo/testing
//  Uses MockDataStore for consistent gym data across services.
//

import Foundation

/// Mock booking history service that provides realistic demo data
/// All gym references come from MockDataStore for consistency
final class MockBookingHistoryService: BookingHistoryServiceProtocol {
    
    // MARK: - Mock State (in-memory persistence during session)
    
    /// List of mock bookings
    private var mockBookings: [Booking]
    
    // MARK: - Initialization
    
    init() {
        self.mockBookings = MockBookingHistoryService.generateMockBookings()
    }
    
    // MARK: - BookingHistoryServiceProtocol
    
    func fetchBookings() async throws -> [Booking] {
        try await simulateNetworkDelay()
        return mockBookings.sorted { $0.startTime > $1.startTime }
    }
    
    func cancelBooking(id: String) async throws -> Booking {
        try await simulateNetworkDelay()
        
        // Deterministic failure for testing: if id contains "fail"
        if id.lowercased().contains("fail") {
            throw BookingHistoryServiceError.cancelFailed("Payment refund failed. Please try again or contact support.")
        }
        
        // Find the booking
        guard let index = mockBookings.firstIndex(where: { $0.id == id }) else {
            throw BookingHistoryServiceError.bookingNotFound
        }
        
        let booking = mockBookings[index]
        
        // Check if already cancelled
        if booking.status == .cancelled {
            throw BookingHistoryServiceError.alreadyCancelled
        }
        
        // Only upcoming/confirmed bookings can be cancelled
        guard booking.status == .confirmed && booking.startTime > Date() else {
            throw BookingHistoryServiceError.cannotCancelNonUpcoming
        }
        
        // Update the booking status
        var updatedBooking = booking
        updatedBooking.status = .cancelled
        updatedBooking.cancelledAt = Date()
        updatedBooking.updatedAt = Date()
        
        mockBookings[index] = updatedBooking
        
        return updatedBooking
    }
    
    // MARK: - Helpers
    
    /// Simulates network delay (300-700ms)
    private func simulateNetworkDelay() async throws {
        let delayMs = Int.random(in: 300...700)
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
    }
    
    // MARK: - Mock Data Generation
    
    /// Generates 12 realistic mock bookings using gyms from MockDataStore
    private static func generateMockBookings() -> [Booking] {
        let calendar = Calendar.current
        let now = Date()
        var bookings: [Booking] = []
        
        let dataStore = MockDataStore.shared
        let userId = MockDataStore.mockUserId
        
        // Get gyms from canonical data store
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
