//
//  WorkoutStats.swift
//  Gym Flex Italia
//
//  Model for workout statistics
//

import Foundation

/// User's workout statistics
struct WorkoutStats: Codable, Equatable {
    /// Total number of workouts completed
    let totalWorkouts: Int
    
    /// Total minutes of workouts
    let totalMinutes: Int
    
    /// Total calories burned (optional, may not always be tracked)
    let totalCalories: Int?
    
    /// Current workout streak (consecutive days with workouts)
    let currentStreak: Int
    
    /// Longest ever workout streak
    let longestStreak: Int
    
    /// Number of workouts this week
    let weeklyWorkouts: Int
    
    /// Number of workouts this month
    let monthlyWorkouts: Int
    
    /// User's favorite gym (most visited)
    let favoriteGym: String?
    
    /// User's favorite workout type
    let favoriteWorkoutType: String?
    
    /// Mock data for previews
    static var mock: WorkoutStats {
        WorkoutStats(
            totalWorkouts: 42,
            totalMinutes: 2100,
            totalCalories: 12500,
            currentStreak: 5,
            longestStreak: 12,
            weeklyWorkouts: 4,
            monthlyWorkouts: 16,
            favoriteGym: "Flex Gym Roma",
            favoriteWorkoutType: "Strength"
        )
    }
}
