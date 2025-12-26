//
//  GroupsService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Groups management service for social fitness features
final class GroupsService {
    
    static let shared = GroupsService()
    
    private let baseURL = AppConfig.API.baseURL
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Fetch Groups
    func fetchGroups(category: GroupCategory? = nil) async throws -> [FitnessGroup] {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/groups")!
        if let category = category {
            components.queryItems = [
                URLQueryItem(name: "category", value: category.rawValue)
            ]
        }
        
        guard let url = components.url else {
            throw GroupsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FitnessGroup].self, from: data)
    }
    
    // MARK: - Fetch My Groups
    func fetchMyGroups() async throws -> [FitnessGroup] {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/groups/my-groups")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FitnessGroup].self, from: data)
    }
    
    // MARK: - Fetch Single Group
    func fetchGroup(id: String) async throws -> FitnessGroup {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/groups/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FitnessGroup.self, from: data)
    }
    
    // MARK: - Create Group
    func createGroup(name: String, description: String?, category: GroupCategory, isPublic: Bool, maxMembers: Int?) async throws -> FitnessGroup {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/groups")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "name": name,
            "category": category.rawValue,
            "is_public": isPublic
        ]
        
        if let description = description {
            body["description"] = description
        }
        if let maxMembers = maxMembers {
            body["max_members"] = maxMembers
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.createFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FitnessGroup.self, from: data)
    }
    
    // MARK: - Join Group
    func joinGroup(id: String) async throws -> GroupMembership {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/groups/\(id)/join")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.joinFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GroupMembership.self, from: data)
    }
    
    // MARK: - Leave Group
    func leaveGroup(id: String) async throws {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/groups/\(id)/leave")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.leaveFailed
        }
    }
    
    // MARK: - Search Groups
    func searchGroups(query: String) async throws -> [FitnessGroup] {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/groups/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        
        guard let url = components.url else {
            throw GroupsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.searchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FitnessGroup].self, from: data)
    }
    
    // MARK: - Fetch Group Messages
    func fetchMessages(groupId: String, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/groups/\(groupId)/messages")!
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        
        if let before = before {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "before", value: formatter.string(from: before)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GroupsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.fetchMessagesFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Message].self, from: data)
    }
    
    // MARK: - Send Message
    func sendMessage(groupId: String, content: String, type: MessageType = .text) async throws -> Message {
        guard let token = authService.getStoredToken() else {
            throw GroupsError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/groups/\(groupId)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "content": content,
            "type": type.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GroupsError.sendMessageFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Message.self, from: data)
    }
}

// MARK: - Groups Errors
enum GroupsError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case fetchFailed
    case createFailed
    case joinFailed
    case leaveFailed
    case searchFailed
    case fetchMessagesFailed
    case sendMessageFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .fetchFailed:
            return "Failed to fetch groups"
        case .createFailed:
            return "Failed to create group"
        case .joinFailed:
            return "Failed to join group"
        case .leaveFailed:
            return "Failed to leave group"
        case .searchFailed:
            return "Search failed"
        case .fetchMessagesFailed:
            return "Failed to fetch messages"
        case .sendMessageFailed:
            return "Failed to send message"
        }
    }
}

