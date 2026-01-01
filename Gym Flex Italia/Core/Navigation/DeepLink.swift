//
//  DeepLink.swift
//  Gym Flex Italia
//
//  Deep link types for app navigation from external sources
//

import Foundation

/// Deep link destinations that can be triggered from notifications, URLs, or other external sources
enum DeepLink: Hashable {
    /// Navigate to gym discovery/booking screen
    case bookSession
    
    /// Navigate to wallet screen
    case wallet
    
    /// Navigate to a specific wallet transaction
    case walletTransaction(String)
    
    /// Navigate to edit profile screen
    case editProfile
    
    /// Navigate to settings screen
    case settings
    
    /// Navigate to booking history
    case bookingHistory
    
    /// Navigate to a specific booking detail
    case bookingDetail(String)
    
    /// Navigate to a specific gym detail
    case gymDetail(String)
    
    /// Navigate to a group via invite link (private group invitation)
    case groupInvite(String) // groupId
}

