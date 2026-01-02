//
//  MockBookingService.swift
//  Gym Flex Italia
//
//  Mock implementation for testing and demo mode
//  Creates bookings and immediately stores them in MockBookingStore.
//

import Foundation

/// Mock implementation of BookingServiceProtocol
/// Simulates booking creation with realistic delays and responses.
/// New bookings are immediately written to MockBookingStore.
final class MockBookingService: BookingServiceProtocol {
    
    // Reference to gym service for getting gym details
    private let gymService: GymServiceProtocol
    
    init(gymService: GymServiceProtocol) {
        self.gymService = gymService
    }
    
    // MARK: - BookingServiceProtocol
    
    @MainActor
    func createBooking(gymId: String, date: Date, duration: Int = 60) async throws -> BookingConfirmation {
        print("🎯 BOOKING FLOW: createBooking called gymId=\(gymId) date=\(date) duration=\(duration)")
        
        // SINGLE ACTIVE SESSION RULE: Check if user already has an active session
        if MockBookingStore.shared.hasActiveSession() {
            print("❌ BOOKING FLOW: Blocked - user already has an active session")
            throw BookingServiceError.activeSessionExists
        }
        
        // Simulate network delay (400-600ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000...600_000_000))
        
        // Check for "fail" in gymId to trigger error (for testing error UI)
        if gymId.lowercased().contains("fail") {
            throw BookingServiceError.bookingFailed
        }
        
        // Try to fetch gym details for confirmation
        var gymName: String = "Selected Gym"
        var gymAddress: String? = nil
        var pricePerHour: Double = 3.0 // Default fallback
        
        do {
            let gym = try await gymService.fetchGymDetail(id: gymId)
            gymName = gym.name
            gymAddress = gym.address
            pricePerHour = gym.pricePerHour
        } catch {
            // Continue with defaults if gym lookup fails
            print("⚠️ BOOKING FLOW: Gym lookup failed, using defaults")
        }
        
        // Calculate total price using PricingCalculator
        let bookingCostCents = PricingCalculator.priceForBooking(
            durationMinutes: duration,
            gymPricePerHour: pricePerHour
        )
        let totalPrice = Double(bookingCostCents) / 100.0
        
        print("💰 BOOKING FLOW: Price calculation - \(duration)min @ €\(String(format: "%.2f", pricePerHour))/h = €\(String(format: "%.2f", totalPrice))")
        
        // Check wallet balance and debit
        let walletStore = WalletStore.shared
        print("💰 BOOKING FLOW: Current wallet balance = €\(String(format: "%.2f", walletStore.balance))")
        
        // Generate reference codes first (needed for wallet transaction)
        let bookingRef = MockDataStore.makeBookingRef()
        let checkInCode = MockDataStore.makeCheckinCode()
        let bookingId = "booking_\(bookingRef)"
        
        // Debit wallet - throws if insufficient funds
        do {
            try walletStore.applyDebitForBooking(
                amountCents: bookingCostCents,
                bookingRef: bookingRef,
                gymName: gymName,
                gymId: gymId
            )
            print("💰 BOOKING FLOW: Wallet debited - new balance = €\(String(format: "%.2f", walletStore.balance))")
        } catch {
            print("❌ BOOKING FLOW: Wallet debit failed - \(error.localizedDescription)")
            throw BookingServiceError.insufficientFunds
        }
        
        // Calculate end time
        let endTime = Calendar.current.date(byAdding: .minute, value: duration, to: date) ?? date
        
        // Create a full Booking object
        let booking = Booking(
            id: bookingId,
            userId: MockDataStore.mockUserId,
            gymId: gymId,
            gymName: gymName,
            gymAddress: gymAddress,
            gymCoverImageURL: nil,
            startTime: date,
            endTime: endTime,
            duration: duration,
            pricePerHour: pricePerHour,
            totalPrice: totalPrice,
            currency: "EUR",
            status: .confirmed,
            checkinCode: checkInCode,
            checkinTime: nil,
            checkoutTime: nil,
            qrCodeData: bookingRef, // Use booking ref as QR data
            qrCodeExpiresAt: date,
            createdAt: Date(),
            updatedAt: Date(),
            cancelledAt: nil,
            cancellationReason: nil
        )
        
        print("📦 BOOKING FLOW: Booking created ref=\(bookingRef) checkInCode=\(checkInCode) start=\(date) end=\(endTime)")
        
        // Store the booking immediately in the shared store
        MockBookingStore.shared.upsert(booking)
        
        // Debug: Dump the store to verify insertion
        print("📊 BOOKING FLOW: Store dump after insert:\n\(MockBookingStore.shared.debugDump())")
        
        // Also update BookingManager for active session tracking
        BookingManager.shared.setActiveBooking(booking)
        
        // Note: Haptics are triggered at UI layer, not here
        
        return BookingConfirmation(
            bookingId: bookingId,
            gymId: gymId,
            gymName: gymName,
            createdAt: Date(),
            referenceCode: bookingRef,
            startTime: date,
            duration: duration,
            totalPrice: totalPrice,
            currency: "EUR"
        )
    }
}

