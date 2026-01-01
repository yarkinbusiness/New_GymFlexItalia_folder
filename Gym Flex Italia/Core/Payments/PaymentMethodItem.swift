//
//  PaymentMethodItem.swift
//  Gym Flex Italia
//
//  Model for payment methods (mock implementation).
//

import Foundation

/// Type of payment method
enum PaymentMethodKind: String, Codable, CaseIterable {
    case applePay = "apple_pay"
    case card = "card"
    
    var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .card: return "Card"
        }
    }
}

/// Card brand for mock cards
enum CardBrand: String, Codable, CaseIterable {
    case visa = "visa"
    case mastercard = "mastercard"
    case amex = "amex"
    
    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        }
    }
    
    var iconName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        }
    }
}

/// Represents a saved payment method
struct PaymentMethodItem: Identifiable, Codable, Hashable {
    let id: String
    let kind: PaymentMethodKind
    var displayName: String
    var brand: String?
    var last4: String?
    var expiryMonth: Int?
    var expiryYear: Int?
    var isDefault: Bool
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        kind: PaymentMethodKind,
        displayName: String,
        brand: String? = nil,
        last4: String? = nil,
        expiryMonth: Int? = nil,
        expiryYear: Int? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.brand = brand
        self.last4 = last4
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.isDefault = isDefault
    }
    
    // MARK: - Convenience Initializers
    
    /// Create a card payment method
    static func card(
        brand: CardBrand,
        last4: String,
        expiryMonth: Int,
        expiryYear: Int,
        isDefault: Bool = false
    ) -> PaymentMethodItem {
        PaymentMethodItem(
            kind: .card,
            displayName: "\(brand.displayName) •••• \(last4)",
            brand: brand.rawValue,
            last4: last4,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            isDefault: isDefault
        )
    }
    
    /// Create Apple Pay payment method
    static var applePay: PaymentMethodItem {
        PaymentMethodItem(
            id: "apple_pay",
            kind: .applePay,
            displayName: "Apple Pay",
            isDefault: false
        )
    }
    
    // MARK: - Computed Properties
    
    /// Subtitle for display (e.g., "Exp 08/27" for cards)
    var subtitle: String? {
        guard kind == .card,
              let month = expiryMonth,
              let year = expiryYear else {
            return nil
        }
        
        let monthStr = String(format: "%02d", month)
        let yearStr = String(format: "%02d", year % 100)
        return "Exp \(monthStr)/\(yearStr)"
    }
    
    /// System icon name for the payment method
    var iconName: String {
        switch kind {
        case .applePay:
            return "applelogo"
        case .card:
            return "creditcard.fill"
        }
    }
    
    /// Card brand enum (if applicable)
    var cardBrand: CardBrand? {
        guard kind == .card, let brandStr = brand else { return nil }
        return CardBrand(rawValue: brandStr)
    }
}
