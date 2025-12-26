//
//  AvatarConfig.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import SwiftUI

/// Avatar configuration and progression system
struct AvatarConfig {
    
    // MARK: - Level System
    static let maxLevel = 10
    static let workoutsPerLevel = 5
    
    static func workoutsNeededForLevel(_ level: Int) -> Int {
        return level * workoutsPerLevel
    }
    
    static func levelForWorkouts(_ totalWorkouts: Int) -> Int {
        let level = totalWorkouts / workoutsPerLevel + 1
        return min(level, maxLevel)
    }
    
    static func progressToNextLevel(currentWorkouts: Int) -> Double {
        let currentLevel = levelForWorkouts(currentWorkouts)
        if currentLevel >= maxLevel {
            return 1.0
        }
        
        let workoutsForCurrentLevel = (currentLevel - 1) * workoutsPerLevel
        let workoutsInCurrentLevel = currentWorkouts - workoutsForCurrentLevel
        return Double(workoutsInCurrentLevel) / Double(workoutsPerLevel)
    }
    
    // MARK: - Avatar Styles
    static func imageNameForStyle(_ style: AvatarStyle, level: Int) -> String {
        return "\(style.rawValue)_level_\(level)"
    }
    
    static func emojiForStyle(_ style: AvatarStyle, level: Int) -> String {
        switch style {
        case .warrior:
            return avatarEmojis[.warrior]?[level] ?? "⚔️"
        case .athlete:
            return avatarEmojis[.athlete]?[level] ?? "🏃"
        case .ninja:
            return avatarEmojis[.ninja]?[level] ?? "🥷"
        case .champion:
            return avatarEmojis[.champion]?[level] ?? "🏆"
        case .beast:
            return avatarEmojis[.beast]?[level] ?? "💪"
        }
    }
    
    private static let avatarEmojis: [AvatarStyle: [Int: String]] = [
        .warrior: [
            1: "🛡️", 2: "⚔️", 3: "🗡️", 4: "🏹", 5: "⚔️",
            6: "🛡️", 7: "⚔️", 8: "👑", 9: "⚔️", 10: "🏆"
        ],
        .athlete: [
            1: "🏃", 2: "🏃‍♂️", 3: "🏃‍♀️", 4: "🤸", 5: "🤸‍♂️",
            6: "🤸‍♀️", 7: "🏋️", 8: "🏋️‍♂️", 9: "🏋️‍♀️", 10: "🥇"
        ],
        .ninja: [
            1: "🥷", 2: "🥷", 3: "🥷", 4: "🥷", 5: "🥷",
            6: "🥷", 7: "🥷", 8: "🥷", 9: "🥷", 10: "🐉"
        ],
        .champion: [
            1: "🎯", 2: "🏅", 3: "🥉", 4: "🥈", 5: "🥇",
            6: "🏆", 7: "👑", 8: "💎", 9: "⭐", 10: "🌟"
        ],
        .beast: [
            1: "💪", 2: "💪", 3: "🦁", 4: "🦁", 5: "🐯",
            6: "🐯", 7: "🦅", 8: "🦅", 9: "🐉", 10: "🔥"
        ]
    ]
    
    // MARK: - Level Titles
    static func titleForLevel(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Novice"
        case 3: return "Apprentice"
        case 4: return "Intermediate"
        case 5: return "Advanced"
        case 6: return "Expert"
        case 7: return "Master"
        case 8: return "Elite"
        case 9: return "Legend"
        case 10: return "Champion"
        default: return "Unknown"
        }
    }
    
    // MARK: - Colors
    static func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 1...2: return .gray
        case 3...4: return .green
        case 5...6: return .blue
        case 7...8: return .purple
        case 9...10: return .orange
        default: return .gray
        }
    }
    
    // MARK: - Achievements
    static let achievements = [
        Achievement(id: "first_workout", title: "First Step", description: "Complete your first workout", icon: "flag.fill", requiredWorkouts: 1),
        Achievement(id: "week_streak", title: "Week Warrior", description: "7 day streak", icon: "flame.fill", requiredWorkouts: 7),
        Achievement(id: "month_streak", title: "Monthly Master", description: "30 day streak", icon: "calendar.badge.plus", requiredWorkouts: 30),
        Achievement(id: "level_5", title: "Halfway There", description: "Reach level 5", icon: "star.fill", requiredWorkouts: 20),
        Achievement(id: "level_10", title: "Max Level", description: "Reach level 10", icon: "crown.fill", requiredWorkouts: 45),
        Achievement(id: "hundred_club", title: "Century", description: "Complete 100 workouts", icon: "100.circle.fill", requiredWorkouts: 100)
    ]
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requiredWorkouts: Int
}

// MARK: - Avatar Progression
struct AvatarProgression {
    var currentLevel: Int
    var totalWorkouts: Int
    var currentStreak: Int
    var style: AvatarStyle
    
    var progressToNextLevel: Double {
        AvatarConfig.progressToNextLevel(currentWorkouts: totalWorkouts)
    }
    
    var workoutsUntilNextLevel: Int {
        let nextLevel = currentLevel + 1
        guard nextLevel <= AvatarConfig.maxLevel else { return 0 }
        let workoutsNeeded = AvatarConfig.workoutsNeededForLevel(nextLevel)
        return max(0, workoutsNeeded - totalWorkouts)
    }
    
    var isMaxLevel: Bool {
        currentLevel >= AvatarConfig.maxLevel
    }
    
    var emoji: String {
        AvatarConfig.emojiForStyle(style, level: currentLevel)
    }
    
    var title: String {
        AvatarConfig.titleForLevel(currentLevel)
    }
    
    var color: Color {
        AvatarConfig.colorForLevel(currentLevel)
    }
}

