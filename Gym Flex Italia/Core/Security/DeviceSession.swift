//
//  DeviceSession.swift
//  Gym Flex Italia
//
//  Model for device/session tracking.
//

import Foundation

/// Represents a device session
struct DeviceSession: Identifiable, Codable, Hashable {
    let id: String
    var deviceName: String
    var platform: String
    var lastActiveAt: Date
    var location: String?
    var isCurrentDevice: Bool
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        deviceName: String,
        platform: String = "iOS",
        lastActiveAt: Date = Date(),
        location: String? = nil,
        isCurrentDevice: Bool = false
    ) {
        self.id = id
        self.deviceName = deviceName
        self.platform = platform
        self.lastActiveAt = lastActiveAt
        self.location = location
        self.isCurrentDevice = isCurrentDevice
    }
    
    // MARK: - Computed Properties
    
    /// Formatted last active time
    var lastActiveFormatted: String {
        if isCurrentDevice {
            return "Active now"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastActiveAt, relativeTo: Date())
    }
    
    /// Platform icon name
    var platformIcon: String {
        switch platform.lowercased() {
        case "ios":
            return "iphone"
        case "ipados":
            return "ipad"
        case "macos":
            return "laptopcomputer"
        case "web":
            return "globe"
        default:
            return "desktopcomputer"
        }
    }
}
