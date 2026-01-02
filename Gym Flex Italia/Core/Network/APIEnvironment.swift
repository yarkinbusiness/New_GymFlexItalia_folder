//
//  APIEnvironment.swift
//  Gym Flex Italia
//
//  API environment configuration with host allowlisting.
//

import Foundation

/// API environment configuration
/// Contains base URL and security constraints for network requests.
struct APIEnvironment {
    /// Base URL for all API requests
    let baseURL: URL
    
    /// Set of allowed hosts - requests to other hosts will be blocked
    let allowedHosts: Set<String>
    
    /// Environment name for logging/debugging
    let name: String
    
    /// Request timeout in seconds
    let timeout: TimeInterval
    
    /// Creates an API environment
    /// - Parameters:
    ///   - baseURL: Base URL for API requests
    ///   - allowedHosts: Set of allowed host names
    ///   - name: Environment name
    ///   - timeout: Request timeout (default: 15 seconds)
    init(
        baseURL: URL,
        allowedHosts: Set<String>,
        name: String,
        timeout: TimeInterval = 15.0
    ) {
        self.baseURL = baseURL
        self.allowedHosts = allowedHosts
        self.name = name
        self.timeout = timeout
    }
    
    /// Validates that a host is allowed
    /// - Parameter host: The host to validate
    /// - Returns: true if the host is in the allowlist
    func isHostAllowed(_ host: String?) -> Bool {
        guard let host = host else { return false }
        return allowedHosts.contains(host)
    }
}

// MARK: - Environment Factories

extension APIEnvironment {
    /// Demo environment - uses placeholder URL, never actually called
    /// Demo mode uses mock services instead of network calls.
    static func demo() -> APIEnvironment {
        APIEnvironment(
            // Placeholder URL - demo mode uses mocks, not network
            baseURL: URL(string: "https://example.invalid")!,
            allowedHosts: ["example.invalid"],
            name: "Demo"
        )
    }
    
    /// Live/Production environment
    /// Points to the real API server.
    static func live() -> APIEnvironment {
        APIEnvironment(
            baseURL: URL(string: "https://api.gymflexitalia.com")!,
            allowedHosts: ["api.gymflexitalia.com"],
            name: "Live"
        )
    }
    
    /// Staging environment for testing
    static func staging() -> APIEnvironment {
        APIEnvironment(
            baseURL: URL(string: "https://staging-api.gymflexitalia.com")!,
            allowedHosts: ["staging-api.gymflexitalia.com"],
            name: "Staging"
        )
    }
}
