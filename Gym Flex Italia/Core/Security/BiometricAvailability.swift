//
//  BiometricAvailability.swift
//  Gym Flex Italia
//
//  Helper to check biometric authentication availability.
//

import Foundation
import LocalAuthentication

/// Helper for biometric authentication availability
struct BiometricAvailability {
    
    /// Returns the supported biometric type, or nil if none available.
    ///
    /// - Returns: "Face ID", "Touch ID", or nil
    static func supportedType() -> String? {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            #if DEBUG
            print("🔐 BiometricAvailability: Not available - \(error?.localizedDescription ?? "unknown")")
            #endif
            return nil
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return nil
        @unknown default:
            return nil
        }
    }
    
    /// Whether any biometric is available
    static var isAvailable: Bool {
        supportedType() != nil
    }
    
    /// Icon name for the available biometric type
    static var iconName: String {
        switch supportedType() {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        case "Optic ID":
            return "opticid"
        default:
            return "lock.shield"
        }
    }
}
