//
//  WalletBalance.swift
//  Gym Flex Italia
//
//  Model representing wallet balance
//

import Foundation

/// Represents the user's wallet balance
struct WalletBalance: Codable, Equatable {
    /// Currency code (e.g., "EUR")
    let currency: String
    
    /// Balance amount in cents (e.g., 4500 = €45.00)
    let amountCents: Int
    
    /// Balance as a formatted decimal value
    var amount: Double {
        Double(amountCents) / 100.0
    }
    
    /// Formatted balance string (e.g., "€45.00")
    var formattedBalance: String {
        let currencySymbol = currency == "EUR" ? "€" : currency
        return "\(currencySymbol)\(String(format: "%.2f", amount))"
    }
    
    /// Default EUR balance
    static func eur(cents: Int) -> WalletBalance {
        WalletBalance(currency: "EUR", amountCents: cents)
    }
}
