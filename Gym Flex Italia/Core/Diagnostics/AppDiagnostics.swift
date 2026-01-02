//
//  AppDiagnostics.swift
//  Gym Flex Italia
//
//  Provides diagnostic information for support and bug reports.
//

import Foundation
import UIKit

/// Provides diagnostic information for support and bug reports
struct AppDiagnostics {
    
    // MARK: - Version Info
    
    /// App version string (e.g., "1.0.0")
    static func appVersionString() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number string (e.g., "42")
    static func buildNumberString() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Full version string (e.g., "1.0.0 (42)")
    static func fullVersionString() -> String {
        "\(appVersionString()) (\(buildNumberString()))"
    }
    
    // MARK: - Environment Info
    
    /// Current app environment
    static func environmentString() -> String {
        AppConfig.environment.rawValue.capitalized
    }
    
    // MARK: - Device Info
    
    /// iOS version string
    static func iosVersionString() -> String {
        UIDevice.current.systemVersion
    }
    
    /// Device model string
    static func deviceModelString() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return deviceName(for: identifier)
    }
    
    /// Combined device info
    static func deviceInfoString() -> String {
        "iOS \(iosVersionString()) • \(deviceModelString())"
    }
    
    // MARK: - Locale Info
    
    /// Current locale string
    static func localeString() -> String {
        Locale.current.identifier
    }
    
    /// Current timezone string
    static func timezoneString() -> String {
        TimeZone.current.identifier
    }
    
    // MARK: - Full Diagnostics
    
    /// Complete diagnostics summary for support emails
    static func diagnosticsSummary() -> String {
        """
        --- App Diagnostics ---
        App Version: \(fullVersionString())
        Environment: \(environmentString())
        Device: \(deviceModelString())
        iOS Version: \(iosVersionString())
        Locale: \(localeString())
        Timezone: \(timezoneString())
        Date: \(ISO8601DateFormatter().string(from: Date()))
        -----------------------
        """
    }
    
    /// Short diagnostics for inline display
    static func shortDiagnostics() -> String {
        "v\(appVersionString()) • \(environmentString()) • iOS \(iosVersionString())"
    }
    
    // MARK: - Private Helpers
    
    private static func deviceName(for identifier: String) -> String {
        switch identifier {
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "x86_64", "arm64": return "Simulator"
        default: return identifier
        }
    }
}
