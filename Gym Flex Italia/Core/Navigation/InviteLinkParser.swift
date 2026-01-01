//
//  InviteLinkParser.swift
//  Gym Flex Italia
//
//  Parser for group invite link URLs.
//  Format: gymflex://invite?groupId=<id>
//

import Foundation

/// Parser for group invite link URLs
struct InviteLinkParser {
    
    /// Parse a URL into a DeepLink if it matches the invite link format.
    ///
    /// Expected format: gymflex://invite?groupId=<groupId>
    ///
    /// - Parameter url: The URL to parse
    /// - Returns: A `.groupInvite` DeepLink if valid, nil otherwise
    static func parse(url: URL) -> DeepLink? {
        // Check scheme
        guard url.scheme == "gymflex" else {
            print("🔗 InviteLinkParser: Invalid scheme '\(url.scheme ?? "nil")' (expected 'gymflex')")
            return nil
        }
        
        // Check host
        guard url.host == "invite" else {
            print("🔗 InviteLinkParser: Invalid host '\(url.host ?? "nil")' (expected 'invite')")
            return nil
        }
        
        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("🔗 InviteLinkParser: No query parameters found")
            return nil
        }
        
        // Find groupId parameter
        guard let groupId = queryItems.first(where: { $0.name == "groupId" })?.value,
              !groupId.isEmpty else {
            print("🔗 InviteLinkParser: Missing or empty 'groupId' parameter")
            return nil
        }
        
        print("🔗 InviteLinkParser: Parsed invite link for groupId=\(groupId)")
        return .groupInvite(groupId)
    }
}
