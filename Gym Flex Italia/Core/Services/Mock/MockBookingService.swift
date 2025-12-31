//
//  MockBookingService.swift
//  Gym Flex Italia
//
//  Mock implementation for testing and demo mode
//

import Foundation

/// Mock implementation of BookingServiceProtocol
/// Simulates booking creation with realistic delays and responses
final class MockBookingService: BookingServiceProtocol {
    
    // Reference to gym service for getting gym details
    private let gymService: GymServiceProtocol
    
    init(gymService: GymServiceProtocol) {
        self.gymService = gymService
    }
    
    // MARK: - BookingServiceProtocol
    
    func createBooking(gymId: String, date: Date, duration: Int = 60) async throws -> BookingConfirmation {
        // Simulate network delay (400-600ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000...600_000_000))
        
        // Check for "fail" in gymId to trigger error (for testing error UI)
        if gymId.lowercased().contains("fail") {
            throw BookingServiceError.bookingFailed
        }
        
        // Try to fetch gym details for confirmation
        var gymName: String? = nil
        var pricePerHour: Double = 3.0 // Default fallback
        
        do {
            let gym = try await gymService.fetchGymDetail(id: gymId)
            gymName = gym.name
            pricePerHour = gym.pricePerHour
        } catch {
            // Continue with defaults if gym lookup fails
            gymName = "Selected Gym"
        }
        
        // Calculate total price
        let hours = Double(duration) / 60.0
        let totalPrice = pricePerHour * hours
        
        // Generate unique booking ID and reference code
        let bookingId = "booking_\(UUID().uuidString.prefix(8))"
        let referenceCode = generateReferenceCode()
        
        return BookingConfirmation(
            bookingId: bookingId,
            gymId: gymId,
            gymName: gymName,
            createdAt: Date(),
            referenceCode: referenceCode,
            startTime: date,
            duration: duration,
            totalPrice: totalPrice,
            currency: "EUR"
        )
    }
    
    // MARK: - Helpers
    
    /// Generates a human-readable reference code (e.g., "GF-AB12C3")
    private func generateReferenceCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomPart = String((0..<6).map { _ in characters.randomElement()! })
        return "GF-\(randomPart)"
    }
}
