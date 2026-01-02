//
//  SafeLog.swift
//  Gym Flex Italia
//
//  Safe logging that masks sensitive data.
//

import Foundation

/// Safe logging utility that masks sensitive information
struct SafeLog {
    
    // MARK: - Sensitive Patterns
    
    private static let sensitivePatterns: [(pattern: String, replacement: String)] = [
        // Email addresses
        ("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "[EMAIL_MASKED]"),
        // Phone numbers (international formats)
        ("\\+?[0-9]{10,15}", "[PHONE_MASKED]"),
        // Auth tokens (Bearer tokens)
        ("Bearer\\s+[A-Za-z0-9._-]+", "Bearer [TOKEN_MASKED]"),
        // Generic tokens (32+ char alphanumeric)
        ("[A-Za-z0-9._-]{32,}", "[TOKEN_MASKED]"),
        // Credit card numbers
        ("\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}", "[CARD_MASKED]")
    ]
    
    // MARK: - Public Methods
    
    /// Logs a message in DEBUG builds only, masking sensitive data
    static func log(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let maskedMessage = maskSensitiveData(message)
        let filename = (file as NSString).lastPathComponent
        print("[\(filename):\(line)] \(maskedMessage)")
        #endif
    }
    
    /// Logs a message with a prefix in DEBUG builds only
    static func log(_ prefix: String, _ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let maskedMessage = maskSensitiveData(message)
        let filename = (file as NSString).lastPathComponent
        print("[\(filename):\(line)] \(prefix): \(maskedMessage)")
        #endif
    }
    
    /// Logs a warning in DEBUG builds only
    static func warn(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let maskedMessage = maskSensitiveData(message)
        let filename = (file as NSString).lastPathComponent
        print("⚠️ [\(filename):\(line)] \(maskedMessage)")
        #endif
    }
    
    /// Logs an error in DEBUG builds only
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let maskedMessage = maskSensitiveData(message)
        let filename = (file as NSString).lastPathComponent
        print("❌ [\(filename):\(line)] \(maskedMessage)")
        #endif
    }
    
    // MARK: - Private Methods
    
    private static func maskSensitiveData(_ input: String) -> String {
        var result = input
        
        for (pattern, replacement) in sensitivePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: replacement
                )
            }
        }
        
        return result
    }
}
