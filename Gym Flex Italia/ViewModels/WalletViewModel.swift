//
//  WalletFullViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for the complete wallet screen with balance and transactions
//

import Foundation
import Combine

/// ViewModel for the wallet screen
@MainActor
final class WalletFullViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message (nil if no error)
    @Published var errorMessage: String?
    
    /// Success message after top-up
    @Published var topUpSuccessMessage: String?
    
    /// Current wallet balance
    @Published var balance: WalletBalance?
    
    /// List of transactions
    @Published var transactions: [WalletTransaction] = []
    
    /// Is top-up in progress
    @Published var isTopUpLoading = false
    
    // MARK: - Public Methods
    
    /// Loads balance and transactions
    func load(using service: WalletServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch balance and transactions in parallel
            async let balanceTask = service.fetchBalance()
            async let transactionsTask = service.fetchTransactions()
            
            let (fetchedBalance, fetchedTransactions) = try await (balanceTask, transactionsTask)
            
            balance = fetchedBalance
            transactions = fetchedTransactions
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Refreshes only the balance and transactions (quick refresh)
    func refresh(using service: WalletServiceProtocol) async {
        errorMessage = nil
        
        do {
            async let balanceTask = service.fetchBalance()
            async let transactionsTask = service.fetchTransactions()
            
            let (fetchedBalance, fetchedTransactions) = try await (balanceTask, transactionsTask)
            
            balance = fetchedBalance
            transactions = fetchedTransactions
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Tops up the wallet
    /// - Parameter amountCents: Amount in cents
    func topUp(amountCents: Int, using service: WalletServiceProtocol) async -> Bool {
        isTopUpLoading = true
        errorMessage = nil
        topUpSuccessMessage = nil
        
        do {
            let transaction = try await service.topUp(amountCents: amountCents)
            
            // Update balance
            let newBalance = Int(transaction.balanceAfter * 100)
            balance = WalletBalance.eur(cents: newBalance)
            
            // Add transaction to the list
            transactions.insert(transaction, at: 0)
            
            // Show success message
            let formattedAmount = String(format: "%.2f", Double(amountCents) / 100.0)
            topUpSuccessMessage = "Successfully added €\(formattedAmount) to your wallet!"
            
            isTopUpLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isTopUpLoading = false
            return false
        }
    }
    
    /// Clears error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clears success message
    func clearSuccess() {
        topUpSuccessMessage = nil
    }
    
    /// Gets a transaction by ID
    func transaction(for id: String) -> WalletTransaction? {
        transactions.first { $0.id == id }
    }
    
    // MARK: - Computed Properties
    
    /// Formatted balance string
    var formattedBalance: String {
        balance?.formattedBalance ?? "€0.00"
    }
    
    /// Whether we have any transactions
    var hasTransactions: Bool {
        !transactions.isEmpty
    }
}
