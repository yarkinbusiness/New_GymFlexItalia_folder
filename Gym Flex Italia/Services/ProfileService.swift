//
//  ProfileService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Profile management service
final class ProfileService {
    
    static let shared = ProfileService()
    
    private let baseURL = AppConfig.API.baseURL
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Profile Operations
    func fetchProfile() async throws -> Profile {
        guard let token = authService.getStoredToken() else {
            throw ProfileError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/profile")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProfileError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        guard let token = authService.getStoredToken() else {
            throw ProfileError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(profile)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProfileError.updateFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
    
    // MARK: - Avatar Operations
    func updateAvatarStyle(_ style: AvatarStyle) async throws -> Profile {
        guard let token = authService.getStoredToken() else {
            throw ProfileError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/profile/avatar-style")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["avatar_style": style.rawValue]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProfileError.updateFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
    
    func recordWorkout(bookingId: String) async throws -> Profile {
        guard let token = authService.getStoredToken() else {
            throw ProfileError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/profile/record-workout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["booking_id": bookingId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProfileError.workoutRecordFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
    
    // MARK: - Goals & Preferences
    func updateFitnessGoals(_ goals: [FitnessGoal]) async throws -> Profile {
        guard let token = authService.getStoredToken() else {
            throw ProfileError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/profile/fitness-goals")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let goalsData = try encoder.encode(goals)
        let body: [String: Any] = ["fitness_goals": try JSONSerialization.jsonObject(with: goalsData)]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProfileError.updateFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
    
    // MARK: - Statistics
    func fetchWorkoutStats() async throws -> WorkoutStats {
        guard let token = authService.getStoredToken() else {
            throw ProfileError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/profile/stats")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProfileError.fetchStatsFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkoutStats.self, from: data)
    }
}

// MARK: - Workout Stats
struct WorkoutStats: Codable {
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalCalories: Int?
    let currentStreak: Int
    let longestStreak: Int
    let weeklyWorkouts: Int
    let monthlyWorkouts: Int
    let favoriteGym: String?
    let favoriteWorkoutType: WorkoutType?
    
    enum CodingKeys: String, CodingKey {
        case totalWorkouts = "total_workouts"
        case totalMinutes = "total_minutes"
        case totalCalories = "total_calories"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case weeklyWorkouts = "weekly_workouts"
        case monthlyWorkouts = "monthly_workouts"
        case favoriteGym = "favorite_gym"
        case favoriteWorkoutType = "favorite_workout_type"
    }
}

// MARK: - Profile Errors
enum ProfileError: LocalizedError {
    case notAuthenticated
    case fetchFailed
    case updateFailed
    case workoutRecordFailed
    case fetchStatsFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .fetchFailed:
            return "Failed to fetch profile"
        case .updateFailed:
            return "Failed to update profile"
        case .workoutRecordFailed:
            return "Failed to record workout"
        case .fetchStatsFailed:
            return "Failed to fetch statistics"
        }
    }
}

