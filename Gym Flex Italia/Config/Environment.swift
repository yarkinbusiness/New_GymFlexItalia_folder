//
//  Environment.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Application environment configuration
enum AppEnvironment: String {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"
    
    var isDevelopment: Bool {
        return self == .development
    }
    
    var isProduction: Bool {
        return self == .production
    }
    
    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://dev-api.gymflexitalia.com"
        case .staging:
            return "https://staging-api.gymflexitalia.com"
        case .production:
            return "https://api.gymflexitalia.com"
        }
    }
    
    var logLevel: LogLevel {
        switch self {
        case .development:
            return .verbose
        case .staging:
            return .debug
        case .production:
            return .error
        }
    }
}

/// Logging levels
enum LogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case none = 5
    
    var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .none: return "NONE"
        }
    }
}

