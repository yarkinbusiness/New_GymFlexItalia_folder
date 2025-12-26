//
//  Profile.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// User profile model
struct Profile: Codable, Identifiable {
    let id: String
    var email: String
    var fullName: String?
    var phoneNumber: String?
    var avatarURL: String?
    var dateOfBirth: Date?
    var gender: Gender?
    
    // Avatar & Gamification
    var avatarLevel: Int
    var totalWorkouts: Int
    var currentStreak: Int
    var longestStreak: Int
    var avatarStyle: AvatarStyle
    
    // Fitness Goals
    var fitnessGoals: [FitnessGoal]
    var preferredWorkoutTypes: [WorkoutType]
    
    // Wallet
    var walletBalance: Double
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var lastWorkoutDate: Date?
    
    enum Gender: String, Codable {
        case male
        case female
        case other
        case preferNotToSay
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case phoneNumber = "phone_number"
        case avatarURL = "avatar_url"
        case dateOfBirth = "date_of_birth"
        case gender
        case avatarLevel = "avatar_level"
        case totalWorkouts = "total_workouts"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case avatarStyle = "avatar_style"
        case fitnessGoals = "fitness_goals"
        case preferredWorkoutTypes = "preferred_workout_types"
        case walletBalance = "wallet_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastWorkoutDate = "last_workout_date"
    }
}

// MARK: - Supporting Types
enum FitnessGoal: String, Codable, CaseIterable {
    case loseWeight = "lose_weight"
    case buildMuscle = "build_muscle"
    case improveEndurance = "improve_endurance"
    case increaseFlexibility = "increase_flexibility"
    case stayActive = "stay_active"
    case generalFitness = "general_fitness"
    
    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .buildMuscle: return "Build Muscle"
        case .improveEndurance: return "Improve Endurance"
        case .increaseFlexibility: return "Increase Flexibility"
        case .stayActive: return "Stay Active"
        case .generalFitness: return "General Fitness"
        }
    }
    
    var icon: String {
        switch self {
        case .loseWeight: return "figure.walk"
        case .buildMuscle: return "dumbbell.fill"
        case .improveEndurance: return "bolt.heart.fill"
        case .increaseFlexibility: return "figure.flexibility"
        case .stayActive: return "figure.run"
        case .generalFitness: return "heart.fill"
        }
    }
}

enum WorkoutType: String, Codable, CaseIterable {
    case cardio
    case strength
    case yoga
    case pilates
    case crossfit
    case boxing
    case swimming
    case cycling
    case hiit
    case other
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .pilates: return "figure.flexibility"
        case .crossfit: return "figure.strengthtraining.traditional"
        case .boxing: return "figure.boxing"
        case .swimming: return "figure.pool.swim"
        case .cycling: return "bicycle"
        case .hiit: return "bolt.fill"
        case .other: return "figure.play"
        }
    }
}

enum AvatarStyle: String, Codable, CaseIterable {
    case warrior
    case athlete
    case ninja
    case champion
    case beast
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Mock Data
extension Profile {
    static var mock: Profile {
        Profile(
            id: "mock_user_123",
            email: "demo@gymflex.it",
            fullName: "Alessandro Rossi",
            phoneNumber: "+39 333 1234567",
            avatarURL: nil,
            dateOfBirth: Date().addingTimeInterval(-31536000 * 25), // 25 years old
            gender: .male,
            avatarLevel: 3,
            totalWorkouts: 15,
            currentStreak: 3,
            longestStreak: 7,
            avatarStyle: .athlete,
            fitnessGoals: [.buildMuscle, .improveEndurance],
            preferredWorkoutTypes: [.strength, .crossfit],
            walletBalance: 25.00,
            createdAt: Date().addingTimeInterval(-31536000), // 1 year ago
            updatedAt: Date(),
            lastWorkoutDate: Date().addingTimeInterval(-86400) // Yesterday
        )
    }
}

