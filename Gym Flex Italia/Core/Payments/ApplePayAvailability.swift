//
//  ApplePayAvailability.swift
//  Gym Flex Italia
//
//  Helper to check Apple Pay availability safely.
//  Returns demo-friendly values in mock mode.
//

import Foundation
import PassKit

/// Helper to check Apple Pay availability
struct ApplePayAvailability {
    
    /// Check if Apple Pay is available on this device.
    ///
    /// In demo/mock mode, this returns true to allow UI testing.
    /// In real mode, checks actual PassKit availability.
    ///
    /// - Returns: true if Apple Pay can be used
    static func isAvailable() -> Bool {
        // In demo mode, always return true for UI testing
        if AppConfig.API.useMocks {
            return true
        }
        
        // Check actual PassKit availability
        return PKPaymentAuthorizationController.canMakePayments()
    }
    
    /// Check if Apple Pay can make payments with specific networks
    static func canMakePayments(with networks: [PKPaymentNetwork]) -> Bool {
        if AppConfig.API.useMocks {
            return true
        }
        
        return PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks)
    }
    
    /// Supported payment networks for the app
    static var supportedNetworks: [PKPaymentNetwork] {
        [.visa, .masterCard, .amex]
    }
}
