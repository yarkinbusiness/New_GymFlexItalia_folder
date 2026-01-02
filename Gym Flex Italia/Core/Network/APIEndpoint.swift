//
//  APIEndpoint.swift
//  Gym Flex Italia
//
//  API endpoint definition for type-safe request building.
//

import Foundation

/// Represents an API endpoint with all request parameters
/// Use this instead of raw string URL building to ensure consistency and security.
struct APIEndpoint {
    /// HTTP method for the request
    let method: HTTPMethod
    
    /// Path component (must start with "/")
    /// Example: "/v1/gyms", "/v1/bookings/123"
    let path: String
    
    /// Query parameters for the URL
    let query: [URLQueryItem]
    
    /// Additional headers for the request
    let headers: [String: String]
    
    /// Request body data (typically JSON-encoded)
    let body: Data?
    
    /// Maximum allowed query string length to prevent URL overflow
    private static let maxQueryLength = 2000
    
    /// Creates an API endpoint
    /// - Parameters:
    ///   - method: HTTP method
    ///   - path: Path component (must start with "/")
    ///   - query: Query parameters (default: empty)
    ///   - headers: Additional headers (default: empty)
    ///   - body: Request body data (default: nil)
    init(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        // Ensure path starts with "/"
        precondition(path.hasPrefix("/"), "APIEndpoint path must start with '/'")
        
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
    }
    
    /// Validates that the query string is within acceptable length limits
    func validateQueryLength() -> Bool {
        let queryString = query.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        return queryString.count <= Self.maxQueryLength
    }
}

// MARK: - Convenience Initializers

extension APIEndpoint {
    /// Creates a GET endpoint
    static func get(
        _ path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) -> APIEndpoint {
        APIEndpoint(method: .GET, path: path, query: query, headers: headers)
    }
    
    /// Creates a POST endpoint with JSON body
    static func post<T: Encodable>(
        _ path: String,
        body: T,
        headers: [String: String] = [:]
    ) throws -> APIEndpoint {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        return APIEndpoint(method: .POST, path: path, body: data)
    }
    
    /// Creates a PUT endpoint with JSON body
    static func put<T: Encodable>(
        _ path: String,
        body: T,
        headers: [String: String] = [:]
    ) throws -> APIEndpoint {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        return APIEndpoint(method: .PUT, path: path, body: data)
    }
    
    /// Creates a PATCH endpoint with JSON body
    static func patch<T: Encodable>(
        _ path: String,
        body: T,
        headers: [String: String] = [:]
    ) throws -> APIEndpoint {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        return APIEndpoint(method: .PATCH, path: path, body: data)
    }
    
    /// Creates a DELETE endpoint
    static func delete(
        _ path: String,
        headers: [String: String] = [:]
    ) -> APIEndpoint {
        APIEndpoint(method: .DELETE, path: path, headers: headers)
    }
}
