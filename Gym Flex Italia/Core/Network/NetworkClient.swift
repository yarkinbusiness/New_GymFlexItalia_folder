//
//  NetworkClient.swift
//  Gym Flex Italia
//
//  Protocol defining network client operations.
//

import Foundation

/// Protocol defining network client operations
/// Implementations must handle authentication, logging, and error mapping.
protocol NetworkClient {
    /// Sends a request and decodes the response
    /// - Parameters:
    ///   - endpoint: The API endpoint to call
    ///   - response: The expected response type
    /// - Returns: Decoded response of type T
    /// - Throws: NetworkError on failure
    func send<T: Decodable>(_ endpoint: APIEndpoint, response: T.Type) async throws -> T
    
    /// Sends a request that returns no content (e.g., DELETE, 204 responses)
    /// - Parameter endpoint: The API endpoint to call
    /// - Throws: NetworkError on failure
    func sendNoContent(_ endpoint: APIEndpoint) async throws
}
