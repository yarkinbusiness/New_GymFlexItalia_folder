//
//  Message.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Message model for group chat
struct Message: Codable, Identifiable {
    let id: String
    let groupId: String
    let userId: String
    
    // User info (denormalized for convenience)
    var userName: String?
    var userAvatarURL: String?
    var userAvatarLevel: Int?
    
    // Message Content
    var content: String
    var type: MessageType
    
    // Attachments (Phase 2+)
    var attachmentURL: String?
    var attachmentType: AttachmentType?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date?
    var isEdited: Bool
    var isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarURL = "user_avatar_url"
        case userAvatarLevel = "user_avatar_level"
        case content
        case type
        case attachmentURL = "attachment_url"
        case attachmentType = "attachment_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
    }
}

// MARK: - Message Type
enum MessageType: String, Codable {
    case text
    case image
    case workout
    case achievement
    case systemNotification = "system_notification"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .workout: return "Workout"
        case .achievement: return "Achievement"
        case .systemNotification: return "System"
        }
    }
}

// MARK: - Attachment Type
enum AttachmentType: String, Codable {
    case image
    case video
    case gif
    case document
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Typing Indicator (Phase 2)
struct TypingIndicator: Codable {
    let groupId: String
    let userId: String
    var userName: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case userName = "user_name"
        case timestamp
    }
}

