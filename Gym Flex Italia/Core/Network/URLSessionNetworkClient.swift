//
//  URLSessionNetworkClient.swift
//  Gym Flex Italia
//
//  URLSession-based network client implementation with security hardening.
//

import Foundation

/// URLSession-based implementation of NetworkClient
/// Features:
/// - Host allowlisting (blocks requests to disallowed hosts)
/// - Automatic auth token injection from Keychain
/// - Secure logging (redacted via SafeLog)
/// - Configurable timeouts
/// - Proper error mapping
final class URLSessionNetworkClient: NetworkClient {
    
    // MARK: - Properties
    
    /// API environment configuration
    let environment: APIEnvironment
    
    /// URL session for network requests
    private let session: URLSession
    
    /// JSON decoder for response parsing
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    /// Creates a network client
    /// - Parameters:
    ///   - environment: API environment configuration
    ///   - session: URLSession to use (default: .shared)
    init(
        environment: APIEnvironment,
        session: URLSession = .shared
    ) {
        self.environment = environment
        self.session = session
        
        // Configure decoder with safe defaults
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - NetworkClient Protocol
    
    func send<T: Decodable>(_ endpoint: APIEndpoint, response: T.Type) async throws -> T {
        let (data, _) = try await executeRequest(endpoint)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logError("Decoding failed for \(endpoint.path)")
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
    
    func sendNoContent(_ endpoint: APIEndpoint) async throws {
        _ = try await executeRequest(endpoint)
    }
    
    // MARK: - Private Methods
    
    /// Executes the network request
    /// - Parameter endpoint: The endpoint to call
    /// - Returns: Tuple of (data, response)
    private func executeRequest(_ endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        // Build the URL
        let url = try buildURL(for: endpoint)
        
        // Validate host is allowed
        guard environment.isHostAllowed(url.host) else {
            logError("Blocked request to disallowed host: \(url.host ?? "unknown")")
            throw NetworkError.disallowedHost
        }
        
        // Validate query length
        guard endpoint.validateQueryLength() else {
            logError("Query string exceeds maximum length")
            throw NetworkError.invalidURL
        }
        
        // Build the request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = environment.timeout
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set content-type for requests with body
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Add auth token if available (from Keychain)
        if let token = KeychainTokenStore.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            // NEVER log the token itself
        }
        
        // Add custom headers
        for (key, value) in endpoint.headers {
            // Skip Authorization header from custom headers (use token store instead)
            guard key.lowercased() != "authorization" else { continue }
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        request.httpBody = endpoint.body
        
        // Log request (DEBUG only, redacted)
        logRequest(endpoint)
        
        // Execute request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            logError("Request timed out: \(endpoint.path)")
            throw NetworkError.timeout
        } catch {
            logError("Request failed: \(endpoint.path)")
            throw NetworkError.requestFailed(underlying: error)
        }
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            logError("Invalid response type for: \(endpoint.path)")
            throw NetworkError.invalidResponse
        }
        
        // Log response (DEBUG only)
        logResponse(endpoint, statusCode: httpResponse.statusCode, dataSize: data.count)
        
        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = parseErrorMessage(from: data)
            logError("HTTP error \(httpResponse.statusCode) for: \(endpoint.path)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
        
        return (data, httpResponse)
    }
    
    /// Builds the full URL for an endpoint
    private func buildURL(for endpoint: APIEndpoint) throws -> URL {
        var components = URLComponents(url: environment.baseURL, resolvingAgainstBaseURL: true)
        components?.path = endpoint.path
        
        if !endpoint.query.isEmpty {
            components?.queryItems = endpoint.query
        }
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    /// Attempts to parse an error message from response body
    private func parseErrorMessage(from data: Data) -> String? {
        // Try to parse common error response formats
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }
        
        guard let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            return nil
        }
        
        return errorResponse.message ?? errorResponse.error
    }
    
    // MARK: - Logging (DEBUG only, redacted)
    
    private func logRequest(_ endpoint: APIEndpoint) {
        #if DEBUG
        let bodyInfo = endpoint.body.map { "body: \($0.count) bytes" } ?? "no body"
        SafeLog.log("🌐 \(endpoint.method.rawValue) \(endpoint.path) (\(bodyInfo))")
        #endif
    }
    
    private func logResponse(_ endpoint: APIEndpoint, statusCode: Int, dataSize: Int) {
        #if DEBUG
        SafeLog.log("✅ \(statusCode) \(endpoint.path) (\(dataSize) bytes)")
        #endif
    }
    
    private func logError(_ message: String) {
        #if DEBUG
        SafeLog.error("❌ NetworkClient: \(message)")
        #endif
    }
}
