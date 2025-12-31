//
//  WalletServiceProtocol.swift
//  Gym Flex Italia
//
//  Protocol defining wallet-related operations
//

import Foundation

/// Errors that can occur during wallet operations
enum WalletServiceError: Error, LocalizedError {
    case fetchBalanceFailed(String)
    case fetchTransactionsFailed(String)
    case topUpFailed(String)
    case invalidAmount(String)
    case insufficientFunds
    case paymentProcessingError
    
    var errorDescription: String? {
        switch self {
        case .fetchBalanceFailed(let message):
            return "Failed to load balance: \(message)"
        case .fetchTransactionsFailed(let message):
            return "Failed to load transactions: \(message)"
        case .topUpFailed(let message):
            return "Top up failed: \(message)"
        case .invalidAmount(let message):
            return message
        case .insufficientFunds:
            return "Insufficient funds in wallet"
        case .paymentProcessingError:
            return "Payment processing error. Please try again."
        }
    }
}

/// Protocol defining wallet service operations
protocol WalletServiceProtocol {
    /// Fetches the current wallet balance
    func fetchBalance() async throws -> WalletBalance
    
    /// Fetches the list of wallet transactions
    func fetchTransactions() async throws -> [WalletTransaction]
    
    /// Tops up the wallet with the specified amount
    /// - Parameter amountCents: Amount in cents (e.g., 1000 = €10.00)
    /// - Returns: The newly created top-up transaction
    func topUp(amountCents: Int) async throws -> WalletTransaction
}
