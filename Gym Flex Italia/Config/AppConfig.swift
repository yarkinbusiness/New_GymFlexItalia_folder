//
//  AppConfig.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Central configuration for the GymFlex Italia app
struct AppConfig {
    
    // MARK: - API Configuration
    struct API {
        static let baseURL: String = {
            switch AppConfig.environment {
            case .development:
                return "https://dev-api.gymflexitalia.com"
            case .staging:
                return "https://staging-api.gymflexitalia.com"
            case .production:
                return "https://api.gymflexitalia.com"
            }
        }()
        
        static let supabaseURL = "https://your-project.supabase.co"
        static let supabaseAnonKey = "your-anon-key-here" // TODO: Move to Secrets.plist
        
        static let timeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
        
        // MARK: - Mock Mode
        static let useMocks = true
    }
    
    // MARK: - Environment
    static let environment: AppEnvironment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    // MARK: - App Info
    struct App {
        static let name = "GymFlex Italia"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        static var fullVersion: String {
            "\(version) (\(build))"
        }
    }
    
    // MARK: - Feature Configuration
    struct Features {
        static let enableApplePay = false // Phase 3
        static let enableWallet = false // Phase 2
        static let enableGroupChat = true // Phase 2
        static let enableAvatarSystem = true
        static let enableQRCheckin = true
        static let enablePushNotifications = true
        
        static let maxBookingDaysInAdvance = 30
        static let minBookingDuration = 60 // minutes
        static let maxBookingDuration = 240 // minutes
        
        static let avatarMaxLevel = 10
        static let workoutsPerLevel = 5
    }
    
    // MARK: - Map Configuration
    struct Map {
        static let defaultLatitude = 41.9028 // Rome
        static let defaultLongitude = 12.4964
        static let defaultZoomRadius = 5000.0 // meters
        static let maxSearchRadius = 50000.0 // 50km
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let imageCacheSize = 100 * 1024 * 1024 // 100MB
        static let gymsCacheExpiry: TimeInterval = 3600 // 1 hour
        static let profileCacheExpiry: TimeInterval = 1800 // 30 minutes
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration = 0.3
        static let cornerRadius = 20.0
        static let cardCornerRadius = 24.0
        static let shadowRadius = 10.0
        static let glassMaterialThickness = 50.0
    }
}

