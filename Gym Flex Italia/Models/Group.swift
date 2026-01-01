//
//  Group.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Group model for social fitness groups
struct FitnessGroup: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var coverImageURL: String?
    
    // Group Details
    var category: GroupCategory
    var tags: [String]
    var isPublic: Bool
    var maxMembers: Int?
    
    // Creator & Members
    var creatorId: String
    var creatorName: String?
    var memberCount: Int
    var memberIds: [String]
    
    // Location (optional)
    var city: String?
    var region: String?
    
    // Stats
    var totalWorkouts: Int
    var averageLevel: Double?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case coverImageURL = "cover_image_url"
        case category
        case tags
        case isPublic = "is_public"
        case maxMembers = "max_members"
        case creatorId = "creator_id"
        case creatorName = "creator_name"
        case memberCount = "member_count"
        case memberIds = "member_ids"
        case city
        case region
        case totalWorkouts = "total_workouts"
        case averageLevel = "average_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed Properties
    var isFull: Bool {
        guard let max = maxMembers else { return false }
        return memberCount >= max
    }
    
    /// Whether this is a private group (inverse of isPublic)
    var isPrivate: Bool {
        !isPublic
    }
    
    /// Invite link URL for private group sharing
    /// Format: gymflex://invite?groupId=<id>
    var inviteLink: URL {
        URL(string: "gymflex://invite?groupId=\(id)")!
    }
    
    /// Share text for invite link
    var shareText: String {
        "Join my GymFlex group '\(name)': gymflex://invite?groupId=\(id)"
    }
}

// MARK: - Group Category
enum GroupCategory: String, Codable, CaseIterable {
    case general
    case cardio
    case strength
    case yoga
    case crossfit
    case running
    case cycling
    case swimming
    case martialArts = "martial_arts"
    case beginners
    case advanced
    case women
    case seniors
    case students
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .cardio: return "Cardio"
        case .strength: return "Strength Training"
        case .yoga: return "Yoga & Pilates"
        case .crossfit: return "CrossFit"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .martialArts: return "Martial Arts"
        case .beginners: return "Beginners"
        case .advanced: return "Advanced"
        case .women: return "Women Only"
        case .seniors: return "Seniors"
        case .students: return "Students"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "person.3.fill"
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .crossfit: return "figure.strengthtraining.traditional"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .martialArts: return "figure.martial.arts"
        case .beginners: return "star.fill"
        case .advanced: return "bolt.fill"
        case .women: return "person.fill"
        case .seniors: return "figure.walk"
        case .students: return "graduationcap.fill"
        }
    }
}

// MARK: - Group Membership
struct GroupMembership: Codable, Identifiable {
    let id: String
    let groupId: String
    let userId: String
    var role: MemberRole
    var joinedAt: Date
    
    enum MemberRole: String, Codable {
        case owner
        case admin
        case member
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}

