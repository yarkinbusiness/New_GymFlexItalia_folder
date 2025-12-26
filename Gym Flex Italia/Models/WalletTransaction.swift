//
//  WalletTransaction.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Wallet transaction model (Phase 2/3)
struct WalletTransaction: Codable, Identifiable {
    let id: String
    let userId: String
    
    // Transaction Details
    var type: TransactionType
    var amount: Double
    var currency: String
    var description: String
    
    // Related Entities
    var bookingId: String?
    var gymId: String?
    var gymName: String?
    
    // Payment Method (Phase 3)
    var paymentMethod: PaymentMethod?
    var paymentProvider: String?
    var paymentTransactionId: String?
    
    // Balance
    var balanceBefore: Double
    var balanceAfter: Double
    
    // Status
    var status: TransactionStatus
    
    // Metadata
    var createdAt: Date
    var processedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case amount
        case currency
        case description
        case bookingId = "booking_id"
        case gymId = "gym_id"
        case gymName = "gym_name"
        case paymentMethod = "payment_method"
        case paymentProvider = "payment_provider"
        case paymentTransactionId = "payment_transaction_id"
        case balanceBefore = "balance_before"
        case balanceAfter = "balance_after"
        case status
        case createdAt = "created_at"
        case processedAt = "processed_at"
    }
}

// MARK: - Transaction Type
enum TransactionType: String, Codable {
    case deposit
    case withdrawal
    case payment
    case refund
    case bonus
    case penalty
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .deposit: return "arrow.down.circle.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        case .payment: return "creditcard.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        case .bonus: return "gift.fill"
        case .penalty: return "exclamationmark.triangle.fill"
        }
    }
    
    var isPositive: Bool {
        switch self {
        case .deposit, .refund, .bonus:
            return true
        case .withdrawal, .payment, .penalty:
            return false
        }
    }
}

// MARK: - Transaction Status
enum TransactionStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
    case cancelled
    case refunded
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        }
    }
}

// MARK: - Payment Method (Phase 3)
enum PaymentMethod: String, Codable {
    case wallet
    case applePay = "apple_pay"
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    
    var displayName: String {
        switch self {
        case .wallet: return "Wallet"
        case .applePay: return "Apple Pay"
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        }
    }
    
    var icon: String {
        switch self {
        case .wallet: return "wallet.pass.fill"
        case .applePay: return "apple.logo"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        }
    }
}

