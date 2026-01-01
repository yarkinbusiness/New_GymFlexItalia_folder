//
//  WalletStore.swift
//  Gym Flex Italia
//
//  Single source of truth for wallet balance and transactions.
//  Persisted to UserDefaults for data retention across app launches.
//

import Foundation
import Combine

/// Persisted wallet data structure
struct PersistedWalletData: Codable {
    var balanceCents: Int
    var currency: String
    var transactions: [WalletTransaction]
    
    static let defaultDemoData = PersistedWalletData(
        balanceCents: 4500, // €45.00
        currency: "EUR",
        transactions: []
    )
}

/// Single source of truth for wallet balance and transactions.
/// Observed by Home (WalletButtonView) and Wallet screen.
/// Updated by MockWalletService and booking debit flow.
@MainActor
final class WalletStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WalletStore()
    
    // MARK: - Persistence Keys
    
    private static let persistenceKey = "wallet_store_v1"
    
    // MARK: - Published State
    
    /// Current balance in cents
    @Published private(set) var balanceCents: Int = 4500
    
    /// Currency code
    @Published private(set) var currency: String = "EUR"
    
    /// All transactions (newest first)
    @Published private(set) var transactions: [WalletTransaction] = []
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    /// Balance as Double (e.g., 45.00)
    var balance: Double {
        Double(balanceCents) / 100.0
    }
    
    /// WalletBalance struct for compatibility
    var walletBalance: WalletBalance {
        WalletBalance(currency: currency, amountCents: balanceCents)
    }
    
    /// Formatted balance string (e.g., "€45.00")
    var formattedBalance: String {
        String(format: "€%.2f", balance)
    }
    
    /// Whether there are any transactions
    var hasTransactions: Bool {
        !transactions.isEmpty
    }
    
    // MARK: - Initialization
    
    private init() {
        load()
        
        // If no transactions, seed with demo data
        if transactions.isEmpty {
            seedDemoTransactions()
        }
        
        print("💰 WalletStore.init: balance=€\(String(format: "%.2f", balance)) transactions=\(transactions.count)")
    }
    
    // MARK: - Persistence
    
    /// Load wallet data from UserDefaults
    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else {
            print("💰 WalletStore.load: No persisted data, using defaults")
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(PersistedWalletData.self, from: data)
            balanceCents = decoded.balanceCents
            currency = decoded.currency
            transactions = decoded.transactions
            print("💰 WalletStore.load: Loaded balance=€\(String(format: "%.2f", balance)) transactions=\(transactions.count)")
        } catch {
            print("⚠️ WalletStore.load: Failed to decode: \(error)")
        }
    }
    
    /// Save wallet data to UserDefaults
    func save() {
        let data = PersistedWalletData(
            balanceCents: balanceCents,
            currency: currency,
            transactions: transactions
        )
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: Self.persistenceKey)
            print("💰 WalletStore.save: Saved balance=€\(String(format: "%.2f", balance)) transactions=\(transactions.count)")
        } catch {
            print("⚠️ WalletStore.save: Failed to encode: \(error)")
        }
    }
    
    // MARK: - Top Up
    
    /// Apply a top-up to the wallet
    /// - Parameters:
    ///   - amountCents: Amount to add in cents
    ///   - ref: Reference code for the transaction
    ///   - method: Payment method used (optional)
    /// - Returns: The created transaction
    @discardableResult
    func applyTopUp(amountCents: Int, ref: String, method: PaymentMethod? = nil) -> WalletTransaction {
        let balanceBefore = balance
        balanceCents += amountCents
        let balanceAfter = balance
        
        let transaction = WalletTransaction(
            id: UUID().uuidString,
            userId: MockDataStore.mockUserId,
            type: .deposit,
            amount: Double(amountCents) / 100.0,
            currency: currency,
            description: "Wallet Top-up",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: method ?? .wallet,
            paymentProvider: "Mock",
            paymentTransactionId: ref,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            status: .completed,
            createdAt: Date(),
            processedAt: Date()
        )
        
        transactions.insert(transaction, at: 0)
        save()
        
        print("💰 WalletStore.applyTopUp: +€\(String(format: "%.2f", Double(amountCents) / 100.0)) → €\(String(format: "%.2f", balanceAfter))")
        
        return transaction
    }
    
    // MARK: - Debit for Booking
    
    /// Debit the wallet for a booking
    /// - Parameters:
    ///   - amountCents: Amount to debit in cents
    ///   - bookingRef: Booking reference code
    ///   - gymName: Name of the gym
    ///   - gymId: ID of the gym (optional)
    /// - Returns: The created transaction
    /// - Throws: WalletServiceError.insufficientFunds if balance is too low
    @discardableResult
    func applyDebitForBooking(amountCents: Int, bookingRef: String, gymName: String, gymId: String? = nil) throws -> WalletTransaction {
        // Check sufficient balance
        guard balanceCents >= amountCents else {
            print("❌ WalletStore.applyDebitForBooking: Insufficient balance (have €\(String(format: "%.2f", balance)), need €\(String(format: "%.2f", Double(amountCents) / 100.0)))")
            throw WalletServiceError.insufficientFunds
        }
        
        let balanceBefore = balance
        balanceCents -= amountCents
        let balanceAfter = balance
        
        let transaction = WalletTransaction(
            id: UUID().uuidString,
            userId: MockDataStore.mockUserId,
            type: .payment,
            amount: Double(amountCents) / 100.0,
            currency: currency,
            description: "Booking at \(gymName)",
            bookingId: "booking_\(bookingRef)",
            gymId: gymId,
            gymName: gymName,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: bookingRef,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            status: .completed,
            createdAt: Date(),
            processedAt: Date()
        )
        
        transactions.insert(transaction, at: 0)
        save()
        
        print("💰 WalletStore.applyDebitForBooking: -€\(String(format: "%.2f", Double(amountCents) / 100.0)) for '\(gymName)' → €\(String(format: "%.2f", balanceAfter))")
        
        return transaction
    }
    
    // MARK: - Refund
    
    /// Apply a refund to the wallet
    @discardableResult
    func applyRefund(amountCents: Int, bookingRef: String, gymName: String) -> WalletTransaction {
        let balanceBefore = balance
        balanceCents += amountCents
        let balanceAfter = balance
        
        let transaction = WalletTransaction(
            id: UUID().uuidString,
            userId: MockDataStore.mockUserId,
            type: .refund,
            amount: Double(amountCents) / 100.0,
            currency: currency,
            description: "Refund for cancelled booking - \(gymName)",
            bookingId: "booking_\(bookingRef)",
            gymId: nil,
            gymName: gymName,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "REF-\(bookingRef)",
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            status: .completed,
            createdAt: Date(),
            processedAt: Date()
        )
        
        transactions.insert(transaction, at: 0)
        save()
        
        print("💰 WalletStore.applyRefund: +€\(String(format: "%.2f", Double(amountCents) / 100.0)) → €\(String(format: "%.2f", balanceAfter))")
        
        return transaction
    }
    
    // MARK: - Reset
    
    /// Reset wallet to demo defaults (for testing/debugging)
    func resetToDemoDefaults() {
        balanceCents = 4500 // €45.00
        currency = "EUR"
        transactions = []
        seedDemoTransactions()
        save()
        print("💰 WalletStore.resetToDemoDefaults: Reset complete")
    }
    
    // MARK: - Demo Data
    
    /// Seed initial demo transactions
    private func seedDemoTransactions() {
        let dataStore = MockDataStore.shared
        let gyms = dataStore.gyms
        let userId = MockDataStore.mockUserId
        let calendar = Calendar.current
        var currentDate = Date()
        
        // Track running balance backwards from current
        var runningBalance = balance
        
        // Transaction 1: Recent top-up (today)
        let topUp1Amount = 20.00
        transactions.append(WalletTransaction(
            id: "txn_seed_001",
            userId: userId,
            type: .deposit,
            amount: topUp1Amount,
            currency: "EUR",
            description: "Wallet Top-up",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .creditCard,
            paymentProvider: "Mock",
            paymentTransactionId: "WL-SEED01",
            balanceBefore: runningBalance - topUp1Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 2: Booking (yesterday)
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        let gym1 = gyms[0]
        let booking1Amount = gym1.pricePerHour
        runningBalance -= topUp1Amount
        transactions.append(WalletTransaction(
            id: "txn_seed_002",
            userId: userId,
            type: .payment,
            amount: booking1Amount,
            currency: "EUR",
            description: "Booking at \(gym1.name)",
            bookingId: "booking_completed_001",
            gymId: gym1.id,
            gymName: gym1.name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-SEED01",
            balanceBefore: runningBalance + booking1Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 3: Top-up (3 days ago)
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let topUp2Amount = 30.00
        runningBalance += booking1Amount
        transactions.append(WalletTransaction(
            id: "txn_seed_003",
            userId: userId,
            type: .deposit,
            amount: topUp2Amount,
            currency: "EUR",
            description: "Wallet Top-up",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .applePay,
            paymentProvider: "Apple",
            paymentTransactionId: "WL-SEED02",
            balanceBefore: runningBalance - topUp2Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        print("💰 WalletStore: Seeded \(transactions.count) demo transactions")
    }
}
