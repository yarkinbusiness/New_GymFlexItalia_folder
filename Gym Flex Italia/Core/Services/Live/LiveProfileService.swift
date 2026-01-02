//
//  LiveProfileService.swift
//  Gym Flex Italia
//
//  Live implementation of ProfileServiceProtocol using NetworkClient.
//  Scaffold only - endpoints not yet configured.
//

import Foundation

/// Live implementation of ProfileServiceProtocol
/// Uses NetworkClient for real API calls.
/// Currently a scaffold - endpoints will be configured when backend is ready.
final class LiveProfileService: ProfileServiceProtocol {
    
    // MARK: - Properties
    
    private let networkClient: NetworkClient
    
    // MARK: - Initialization
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - ProfileServiceProtocol
    
    func fetchCurrentProfile() async throws -> Profile {
        // Endpoint: GET /v1/profile
        let endpoint = APIEndpoint.get("/v1/profile")
        return try await networkClient.send(endpoint, response: Profile.self)
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        // Endpoint: PUT /v1/profile
        let endpoint = try APIEndpoint.put("/v1/profile", body: profile)
        return try await networkClient.send(endpoint, response: Profile.self)
    }
    
    func recordWorkout(bookingId: String) async throws -> Profile {
        // Endpoint: POST /v1/profile/workouts
        struct RecordWorkoutRequest: Encodable {
            let bookingId: String
        }
        
        let requestBody = RecordWorkoutRequest(bookingId: bookingId)
        let endpoint = try APIEndpoint.post("/v1/profile/workouts", body: requestBody)
        return try await networkClient.send(endpoint, response: Profile.self)
    }
}
