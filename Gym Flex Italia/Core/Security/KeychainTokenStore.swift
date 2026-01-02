//
//  KeychainTokenStore.swift
//  Gym Flex Italia
//
//  Secure token storage using iOS Keychain.
//

import Foundation
import Security

/// Secure token storage using iOS Keychain
/// Replaces UserDefaults for auth token storage
struct KeychainTokenStore {
    
    // MARK: - Constants
    
    private static let service = "com.gymflexitalia.auth"
    private static let tokenAccount = "access_token"
    
    // MARK: - Public Methods
    
    /// Saves the auth token to Keychain
    /// - Parameter token: The authentication token to store
    /// - Returns: True if successful, false otherwise
    @discardableResult
    static func saveToken(_ token: String) -> Bool {
        // First, try to delete any existing token
        clearToken()
        
        guard let tokenData = token.data(using: .utf8) else {
            #if DEBUG
            print("⚠️ KeychainTokenStore: Failed to encode token")
            #endif
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            #if DEBUG
            print("🔐 KeychainTokenStore: Token saved successfully")
            #endif
            return true
        } else {
            #if DEBUG
            print("⚠️ KeychainTokenStore: Failed to save token (status: \(status))")
            #endif
            return false
        }
    }
    
    /// Loads the auth token from Keychain
    /// - Returns: The stored token, or nil if not found
    static func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let tokenData = result as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            if status != errSecItemNotFound {
                #if DEBUG
                print("⚠️ KeychainTokenStore: Failed to load token (status: \(status))")
                #endif
            }
            return nil
        }
        
        #if DEBUG
        print("🔐 KeychainTokenStore: Token loaded successfully")
        #endif
        return token
    }
    
    /// Clears the auth token from Keychain
    @discardableResult
    static func clearToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            #if DEBUG
            print("🔐 KeychainTokenStore: Token cleared")
            #endif
            return true
        } else {
            #if DEBUG
            print("⚠️ KeychainTokenStore: Failed to clear token (status: \(status))")
            #endif
            return false
        }
    }
    
    /// Checks if a token exists in Keychain
    static var hasToken: Bool {
        loadToken() != nil
    }
}
