//
//  MockGymService.swift
//  Gym Flex Italia
//
//  Mock implementation for testing and demo mode
//

import Foundation

/// Mock implementation of GymServiceProtocol
/// Uses MockDataStore for consistent gym data across all services
final class MockGymService: GymServiceProtocol {
    
    // MARK: - GymServiceProtocol
    
    func fetchGyms() async throws -> [Gym] {
        // Simulate network delay (300-500ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        return MockDataStore.shared.gyms
    }
    
    func fetchGymDetail(id: String) async throws -> Gym {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        // Check for "fail" in gymId to trigger error (for testing error UI)
        if id.lowercased().contains("fail") {
            throw GymServiceError.fetchFailed
        }
        
        // Find gym by ID using MockDataStore
        guard let gym = MockDataStore.shared.gymById(id) else {
            throw GymServiceError.gymNotFound
        }
        
        return gym
    }
}
