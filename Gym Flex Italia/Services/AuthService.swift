//
//  AuthService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import AuthenticationServices
import Combine

/// Authentication service handling user auth operations
final class AuthService: ObservableObject {
    
    static let shared = AuthService()
    
    @Published private(set) var currentUser: Profile?
    @Published private(set) var isAuthenticated = false
    
    private let baseURL = AppConfig.API.baseURL
    private let keychainService = "com.gymflexitalia.auth"
    
    private init() {
        // Check for existing session on init
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Auth Status
    func checkAuthStatus() async {
        if AppConfig.API.useMocks {
            // Mock: Check if we have a "mock" token
            if let _ = getStoredToken() {
                await MainActor.run {
                    self.currentUser = Profile.mock
                    self.isAuthenticated = true
                }
            } else {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
            return
        }
        
        guard let token = getStoredToken() else {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
            return
        }
        
        do {
            let profile = try await fetchCurrentProfile(token: token)
            await MainActor.run {
                self.currentUser = profile
                self.isAuthenticated = true
            }
        } catch {
            print("Auth check failed: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
            clearStoredToken()
        }
    }
    
    // MARK: - Email/Password Authentication
    func signUp(email: String, password: String, fullName: String) async throws -> Profile {
        if AppConfig.API.useMocks {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            let mockUser = Profile.mock
            storeToken("mock_token_123")
            
            await MainActor.run {
                self.currentUser = mockUser
                self.isAuthenticated = true
            }
            return mockUser
        }
        
        let url = URL(string: "\(baseURL)/auth/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "full_name": fullName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.signUpFailed
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        storeToken(authResponse.token)
        
        await MainActor.run {
            self.currentUser = authResponse.user
            self.isAuthenticated = true
        }
        
        return authResponse.user
    }
    
    func signIn(email: String, password: String) async throws -> Profile {
        if AppConfig.API.useMocks {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            
            // Simple validation for mock
            if password.count < 3 { throw AuthError.invalidCredentials }
            
            let mockUser = Profile.mock
            storeToken("mock_token_123")
            
            await MainActor.run {
                self.currentUser = mockUser
                self.isAuthenticated = true
            }
            return mockUser
        }
        
        let url = URL(string: "\(baseURL)/auth/signin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidCredentials
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        storeToken(authResponse.token)
        
        await MainActor.run {
            self.currentUser = authResponse.user
            self.isAuthenticated = true
        }
        
        return authResponse.user
    }
    
    // MARK: - Apple Sign In (Phase 1)
    func signInWithApple(authorization: ASAuthorization) async throws -> Profile {
        if AppConfig.API.useMocks {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            let mockUser = Profile.mock
            storeToken("mock_token_apple_123")
            
            await MainActor.run {
                self.currentUser = mockUser
                self.isAuthenticated = true
            }
            return mockUser
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.appleSignInFailed
        }
        
        guard let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }
        
        let url = URL(string: "\(baseURL)/auth/apple")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "id_token": tokenString,
            "user_id": appleIDCredential.user
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.appleSignInFailed
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        storeToken(authResponse.token)
        
        await MainActor.run {
            self.currentUser = authResponse.user
            self.isAuthenticated = true
        }
        
        return authResponse.user
    }
    
    // MARK: - Sign Out
    func signOut() {
        clearStoredToken()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let token = getStoredToken() else {
            throw AuthError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/auth/delete-account")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.deleteAccountFailed
        }
        
        signOut()
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/reset-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.resetPasswordFailed
        }
    }
    
    // MARK: - Helper Methods
    private func fetchCurrentProfile(token: String) async throws -> Profile {
        let url = URL(string: "\(baseURL)/profile")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.fetchProfileFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
    
    // MARK: - Token Management (Keychain)
    func getStoredToken() -> String? {
        return KeychainTokenStore.loadToken()
    }
    
    private func storeToken(_ token: String) {
        KeychainTokenStore.saveToken(token)
    }
    
    private func clearStoredToken() {
        KeychainTokenStore.clearToken()
    }
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let token: String
    let user: Profile
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case signUpFailed
    case appleSignInFailed
    case notAuthenticated
    case deleteAccountFailed
    case resetPasswordFailed
    case fetchProfileFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .signUpFailed:
            return "Failed to create account"
        case .appleSignInFailed:
            return "Apple Sign In failed"
        case .notAuthenticated:
            return "Not authenticated"
        case .deleteAccountFailed:
            return "Failed to delete account"
        case .resetPasswordFailed:
            return "Failed to reset password"
        case .fetchProfileFailed:
            return "Failed to fetch profile"
        }
    }
}

