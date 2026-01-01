//
//  GroupsChatServiceProtocol.swift
//  Gym Flex Italia
//
//  Protocol defining groups and chat service operations.
//  Allows swapping between Mock and Live implementations.
//

import Foundation

/// Protocol defining groups and chat service operations
protocol GroupsChatServiceProtocol {
    
    /// Fetch all groups
    func fetchGroups() async throws -> [FitnessGroup]
    
    /// Fetch groups the user is a member of
    func fetchMyGroups(userId: String) async throws -> [FitnessGroup]
    
    /// Fetch a single group by ID
    func fetchGroup(id: String) async throws -> FitnessGroup
    
    /// Create a new group
    func createGroup(
        name: String,
        description: String?,
        category: GroupCategory,
        isPublic: Bool,
        maxMembers: Int?
    ) async throws -> FitnessGroup
    
    /// Join a group (with specific user ID)
    func joinGroup(id: String, userId: String) async throws
    
    /// Join a group as the current user (returns success)
    func joinGroupAsMember(groupId: String) async throws -> Bool
    
    /// Leave a group
    func leaveGroup(id: String, userId: String) async throws
    
    /// Leave a group as the current user (returns success)
    func leaveGroup(groupId: String) async throws -> Bool
    
    /// Fetch messages for a group
    func fetchMessages(groupId: String) async throws -> [Message]
    
    /// Send a message to a group
    func sendMessage(groupId: String, text: String, userId: String, userName: String) async throws -> Message
}

/// Errors that can occur during groups/chat operations
enum GroupsChatError: LocalizedError {
    case groupNotFound
    case messageFailed
    case createFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return "Group not found"
        case .messageFailed:
            return "Failed to send message"
        case .createFailed:
            return "Failed to create group"
        case .fetchFailed:
            return "Failed to fetch data"
        }
    }
}
