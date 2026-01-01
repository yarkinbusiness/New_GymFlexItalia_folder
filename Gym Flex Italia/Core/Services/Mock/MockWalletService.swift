//
//  MockWalletService.swift
//  Gym Flex Italia
//
//  Mock implementation of WalletServiceProtocol for demo/testing.
//  Uses WalletStore.shared as the single source of truth.
//

import Foundation

/// Mock wallet service that uses WalletStore as the single source of truth.
/// All read/writes go through WalletStore.shared for consistency.
final class MockWalletService: WalletServiceProtocol {
    
    // MARK: - Initialization
    
    init() {
        print("💳 MockWalletService.init: Using WalletStore.shared")
    }
    
    // MARK: - WalletServiceProtocol
    
    @MainActor
    func fetchBalance() async throws -> WalletBalance {
        try await simulateNetworkDelay()
        
        let store = WalletStore.shared
        print("💳 MockWalletService.fetchBalance: €\(String(format: "%.2f", store.balance))")
        return store.walletBalance
    }
    
    @MainActor
    func fetchTransactions() async throws -> [WalletTransaction] {
        try await simulateNetworkDelay()
        
        let store = WalletStore.shared
        print("💳 MockWalletService.fetchTransactions: \(store.transactions.count) transactions")
        return store.transactions
    }
    
    @MainActor
    func topUp(amountCents: Int) async throws -> WalletTransaction {
        try await simulateNetworkDelay()
        
        // Validation: minimum €5.00 (500 cents)
        guard amountCents >= 500 else {
            throw WalletServiceError.invalidAmount("Minimum top-up amount is €5.00")
        }
        
        // Validation: maximum €200.00 (20000 cents)
        guard amountCents <= 20000 else {
            throw WalletServiceError.invalidAmount("Maximum top-up amount is €200.00")
        }
        
        // Deterministic failure for testing: amount == 1337 cents (€13.37)
        if amountCents == 1337 {
            throw WalletServiceError.topUpFailed("Payment declined. Please try a different amount or contact support.")
        }
        
        // Generate reference code
        let referenceCode = MockDataStore.makeWalletRef()
        
        // Apply top-up through WalletStore
        let transaction = WalletStore.shared.applyTopUp(
            amountCents: amountCents,
            ref: referenceCode,
            method: .creditCard
        )
        
        print("💳 MockWalletService.topUp: +€\(String(format: "%.2f", Double(amountCents) / 100.0)) → €\(String(format: "%.2f", WalletStore.shared.balance))")
        
        return transaction
    }
    
    // MARK: - Helpers
    
    /// Simulates network delay (300-700ms)
    private func simulateNetworkDelay() async throws {
        let delayMs = Int.random(in: 300...700)
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
    }
}
