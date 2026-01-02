//
//  NetworkError.swift
//  Gym Flex Italia
//
//  Network layer error types.
//

import Foundation

/// Errors that can occur during network operations
enum NetworkError: Error, LocalizedError {
    /// The URL could not be constructed
    case invalidURL
    
    /// The request host is not in the allowed hosts list
    case disallowedHost
    
    /// The network request failed
    case requestFailed(underlying: Error)
    
    /// The response was not a valid HTTP response
    case invalidResponse
    
    /// The server returned a non-2xx status code
    case httpError(statusCode: Int, message: String?)
    
    /// Failed to decode the response body
    case decodingFailed(underlying: Error)
    
    /// The request timed out
    case timeout
    
    /// Service not yet configured for live mode
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .disallowedHost:
            return "Security error: Request blocked."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error (\(statusCode))"
        case .decodingFailed:
            return "Failed to process server response."
        case .timeout:
            return "Request timed out. Please check your connection."
        case .notConfigured:
            return "This feature is not yet available."
        }
    }
}
