//
//  GymsService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import CoreLocation

/// Gym discovery and search service
final class GymsService {
    
    static let shared = GymsService()
    
    private let baseURL = AppConfig.API.baseURL
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Fetch Gyms
    func fetchGyms(near location: CLLocationCoordinate2D? = nil, 
                   radius: Double = 5000.0, // Default zoom radius in meters
                   filters: GymFilters? = nil,
                   limit: Int? = nil) async throws -> [Gym] {
        
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            var gyms = MockData.sampleGyms
            
            if let location = location {
                gyms.sort { gym1, gym2 in
                    let dist1 = gym1.distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
                    let dist2 = gym2.distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
                    return dist1 < dist2
                }
            }
            
            if let limit = limit {
                return Array(gyms.prefix(limit))
            }
            return gyms
        }
        
        var components = URLComponents(string: "\(baseURL)/gyms")!
        var queryItems: [URLQueryItem] = []
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "latitude", value: String(location.latitude)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(location.longitude)))
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        
        if let filters = filters {
            if let minPrice = filters.minPrice {
                queryItems.append(URLQueryItem(name: "min_price", value: String(minPrice)))
            }
            if let maxPrice = filters.maxPrice {
                queryItems.append(URLQueryItem(name: "max_price", value: String(maxPrice)))
            }
            if !filters.amenities.isEmpty {
                let amenitiesStr = filters.amenities.map { $0.rawValue }.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "amenities", value: amenitiesStr))
            }
            if !filters.workoutTypes.isEmpty {
                let typesStr = filters.workoutTypes.map { $0.rawValue }.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "workout_types", value: typesStr))
            }
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw GymsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = authService.getStoredToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
            throw GymsError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Gym].self, from: data)
    }
    
    // MARK: - Fetch Single Gym
    func fetchGym(id: String) async throws -> Gym {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
            if let gym = MockData.sampleGyms.first(where: { $0.id == id }) {
                return gym
            }
            // Fallback to first gym if ID not found in mocks
            return MockData.sampleGyms[0]
        }
        
        let url = URL(string: "\(baseURL)/gyms/\(id)")!
        var request = URLRequest(url: url)
        
        if let token = authService.getStoredToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
            throw GymsError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Gym.self, from: data)
    }
    
    // MARK: - Search Gyms
    func searchGyms(query: String, near location: CLLocationCoordinate2D? = nil) async throws -> [Gym] {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            return MockData.sampleGyms.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        
        var components = URLComponents(string: "\(baseURL)/gyms/search")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query)
        ]
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "latitude", value: String(location.latitude)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(location.longitude)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GymsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = authService.getStoredToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
            throw GymsError.searchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Gym].self, from: data)
    }
    
    // MARK: - Fetch Gym Availability
    func fetchAvailability(gymId: String, date: Date) async throws -> [AvailabilitySlot] {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s delay
            return MockData.getAvailability(for: date, gymId: gymId)
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)
        
        var components = URLComponents(string: "\(baseURL)/gyms/\(gymId)/availability")!
        components.queryItems = [
            URLQueryItem(name: "date", value: dateString)
        ]
        
        guard let url = components.url else {
            throw GymsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = authService.getStoredToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
            throw GymsError.fetchAvailabilityFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AvailabilitySlot].self, from: data)
    }
}

// MARK: - Gym Filters
struct GymFilters {
    var minPrice: Double?
    var maxPrice: Double?
    var amenities: [Amenity] = []
    var workoutTypes: [WorkoutType] = []
    var minRating: Double?
    var isVerifiedOnly: Bool = false
}

// MARK: - Availability Slot
struct AvailabilitySlot: Codable, Identifiable {
    let id: String
    let gymId: String
    let startTime: Date
    let endTime: Date
    let isAvailable: Bool
    let bookedSlots: Int
    let maxCapacity: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case gymId = "gym_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case isAvailable = "is_available"
        case bookedSlots = "booked_slots"
        case maxCapacity = "max_capacity"
    }
}

// MARK: - Gyms Errors
enum GymsError: LocalizedError {
    case invalidURL
    case fetchFailed
    case searchFailed
    case fetchAvailabilityFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .fetchFailed:
            return "Failed to fetch gyms"
        case .searchFailed:
            return "Search failed"
        case .fetchAvailabilityFailed:
            return "Failed to fetch availability"
        }
    }
}

