//
//  LiveBookingService.swift
//  Gym Flex Italia
//
//  Live implementation of BookingServiceProtocol using NetworkClient.
//  Scaffold only - endpoints not yet configured.
//

import Foundation

/// Live implementation of BookingServiceProtocol
/// Uses NetworkClient for real API calls.
/// Currently a scaffold - endpoints will be configured when backend is ready.
final class LiveBookingService: BookingServiceProtocol {
    
    // MARK: - Properties
    
    private let networkClient: NetworkClient
    
    // MARK: - Initialization
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - BookingServiceProtocol
    
    func createBooking(gymId: String, date: Date, duration: Int) async throws -> BookingConfirmation {
        // Endpoint: POST /v1/bookings
        struct CreateBookingRequest: Encodable {
            let gymId: String
            let startTime: Date
            let duration: Int
        }
        
        let requestBody = CreateBookingRequest(
            gymId: gymId,
            startTime: date,
            duration: duration
        )
        
        let endpoint = try APIEndpoint.post("/v1/bookings", body: requestBody)
        return try await networkClient.send(endpoint, response: BookingConfirmation.self)
    }
}
