//
//  LiveGymService.swift
//  Gym Flex Italia
//
//  Live implementation of GymServiceProtocol using NetworkClient.
//  Scaffold only - endpoints not yet configured.
//

import Foundation

/// Live implementation of GymServiceProtocol
/// Uses NetworkClient for real API calls.
/// Currently a scaffold - endpoints will be configured when backend is ready.
final class LiveGymService: GymServiceProtocol {
    
    // MARK: - Properties
    
    private let networkClient: NetworkClient
    
    // MARK: - Initialization
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - GymServiceProtocol
    
    func fetchGyms() async throws -> [Gym] {
        // Endpoint: GET /v1/gyms
        let endpoint = APIEndpoint.get("/v1/gyms")
        return try await networkClient.send(endpoint, response: [Gym].self)
    }
    
    func fetchGymDetail(id: String) async throws -> Gym {
        // Endpoint: GET /v1/gyms/{id}
        let endpoint = APIEndpoint.get("/v1/gyms/\(id)")
        return try await networkClient.send(endpoint, response: Gym.self)
    }
}
