//
//  AuthViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import AuthenticationServices
import Combine

/// ViewModel for authentication flows
@MainActor
final class AuthViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let authService = AuthService.shared
    
    init() {
        // Observe auth state changes
        isAuthenticated = authService.isAuthenticated
    }
    
    // MARK: - Sign Up
    func signUp() async {
        guard validateSignUp() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.signUp(email: email, password: password, fullName: fullName)
            isAuthenticated = true
            clearFields()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard validateSignIn() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.signIn(email: email, password: password)
            isAuthenticated = true
            clearFields()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(_ authorization: ASAuthorization) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.signInWithApple(authorization: authorization)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
            errorMessage = "Password reset email sent. Please check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        authService.signOut()
        isAuthenticated = false
        clearFields()
    }
    
    // MARK: - Validation
    private func validateSignUp() -> Bool {
        errorMessage = nil
        
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }
        
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"
            return false
        }
        
        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return false
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return false
        }
        
        guard !fullName.isEmpty else {
            errorMessage = "Full name is required"
            return false
        }
        
        return true
    }
    
    private func validateSignIn() -> Bool {
        errorMessage = nil
        
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }
        
        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    private func clearFields() {
        email = ""
        password = ""
        fullName = ""
        confirmPassword = ""
    }
}

