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
    
    // MARK: - Ledger Integrity Helpers
    
    /// Calculate signed amount in cents for a transaction
    /// - Positive for credits (deposits, refunds, bonuses)
    /// - Negative for debits (payments, withdrawals, penalties)
    /// - Zero for pending/failed/cancelled transactions
    func signedAmountCents(_ tx: WalletTransaction) -> Int {
        guard tx.status == .completed else {
            return 0  // Non-completed transactions don't affect balance
        }
        
        let amountCents = Int((tx.amount * 100.0).rounded())
        
        switch tx.type {
        case .deposit, .refund, .bonus:
            return amountCents  // Credits add to balance
        case .payment, .withdrawal, .penalty:
            return -amountCents  // Debits subtract from balance
        }
    }
    
    /// Compute expected balance from completed transactions
    /// Starting from initial demo balance (€45.00 = 4500 cents)
    private var computedBalanceCents: Int {
        let initialBalance = 4500  // Demo starting balance in cents
        return transactions.reduce(initialBalance) { total, tx in
            total + signedAmountCents(tx)
        }
    }
    
    /// Check if a duplicate transaction exists for the given paymentTransactionId
    func hasDuplicateTransaction(paymentTransactionId: String) -> Bool {
        return transactions.contains { tx in
            tx.paymentTransactionId == paymentTransactionId &&
            tx.status == .completed
        }
    }
    
    /// Find existing transaction by paymentTransactionId
    func existingTransaction(paymentTransactionId: String) -> WalletTransaction? {
        return transactions.first { tx in
            tx.paymentTransactionId == paymentTransactionId &&
            tx.status == .completed
        }
    }
    
    // MARK: - Ledger Validation (DEBUG)
    
    /// Validate ledger integrity (DEBUG only)
    /// Checks that stored balance matches computed balance from transactions
    /// - Parameter context: Description of where validation is being called
    func validateLedgerIntegrity(context: String) {
        #if DEBUG
        let computed = computedBalanceCents
        let stored = balanceCents
        
        if computed != stored {
            let diff = stored - computed
            print("⚠️ LEDGER MISMATCH [\(context)]: stored=\(stored)¢ computed=\(computed)¢ diff=\(diff)¢")
            print("   Transactions: \(transactions.count)")
            
            // Log last 5 transactions for debugging
            for (i, tx) in transactions.prefix(5).enumerated() {
                print("   [\(i)] \(tx.type.rawValue) \(signedAmountCents(tx))¢ status=\(tx.status.rawValue) id=\(tx.paymentTransactionId ?? "nil")")
            }
            
            // Only assert if migration was already attempted (meaning real bug, not stale data)
            let migrationKey = "wallet_ledger_migrated_v1"
            if UserDefaults.standard.bool(forKey: migrationKey) {
                assertionFailure("Ledger integrity violation (post-migration): \(context)")
            }
        } else {
            print("✅ LEDGER OK [\(context)]: \(stored)¢ = €\(String(format: "%.2f", Double(stored) / 100.0))")
        }
        #endif
    }
    
    // MARK: - Initialization
    
    private static let migrationKey = "wallet_ledger_migrated_v1"
    
    private init() {
        load()
        
        // If no transactions, seed with demo data
        if transactions.isEmpty {
            seedDemoTransactions()
        }
        
        // DEBUG-only: Auto-heal ledger mismatch from old persisted data
        #if DEBUG
        performLedgerMigrationIfNeeded()
        #endif
        
        print("💰 WalletStore.init: balance=€\(String(format: "%.2f", balance)) transactions=\(transactions.count)")
        validateLedgerIntegrity(context: "init")
    }
    
    /// DEBUG-only: Detect and repair ledger mismatch from stale persisted data
    private func performLedgerMigrationIfNeeded() {
        #if DEBUG
        let computed = computedBalanceCents
        let stored = balanceCents
        
        if computed != stored {
            if !UserDefaults.standard.bool(forKey: Self.migrationKey) {
                // First-time mismatch: auto-repair
                print("🧯 WALLET MIGRATION v1: fixing stored balance to match computed ledger.")
                print("   stored=\(stored)¢ → computed=\(computed)¢")
                balanceCents = computed
                save()
                UserDefaults.standard.set(true, forKey: Self.migrationKey)
                print("🧯 WALLET MIGRATION v1: repair complete, flag set.")
            } else {
                // Migration already done but still mismatched = real bug
                print("⚠️ WALLET: ledger mismatch persists AFTER migration flag. This is a real bug!")
                print("   stored=\(stored)¢ computed=\(computed)¢ diff=\(stored - computed)¢")
            }
        } else if !UserDefaults.standard.bool(forKey: Self.migrationKey) {
            // No mismatch and no migration needed, but mark as migrated for future
            UserDefaults.standard.set(true, forKey: Self.migrationKey)
        }
        #endif
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
    /// - Returns: The created transaction (or existing if duplicate)
    @discardableResult
    func applyTopUp(amountCents: Int, ref: String, method: PaymentMethod? = nil) -> WalletTransaction {
        // Idempotency check: return existing transaction if duplicate
        if let existing = existingTransaction(paymentTransactionId: ref) {
            print("💰 WalletStore.applyTopUp: Duplicate prevented, returning existing tx ref=\(ref)")
            return existing
        }
        
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
        validateLedgerIntegrity(context: "applyTopUp")
        
        return transaction
    }
    
    // MARK: - Total Paid Calculation
    
    /// Calculate total paid for a booking (initial + all extensions)
    /// - Parameter bookingId: The booking ID to calculate total for
    /// - Returns: Total paid in cents
    func totalPaidCents(for bookingId: String) -> Int {
        let relatedPayments = transactions.filter { tx in
            tx.type == .payment &&
            tx.bookingId == bookingId &&
            tx.status == .completed
        }
        
        // Sum all payment amounts (stored as positive values in cents)
        let totalCents = relatedPayments.reduce(0) { total, tx in
            total + Int((tx.amount * 100.0).rounded())
        }
        
        return max(0, totalCents)
    }
    
    // MARK: - Debit for Booking
    
    /// Debit the wallet for a booking
    /// - Parameters:
    ///   - amountCents: Amount to debit in cents
    ///   - bookingRef: Booking reference code
    ///   - gymName: Name of the gym
    ///   - gymId: ID of the gym (optional)
    ///   - bookingIdOverride: Real booking ID for stable linkage (optional, defaults to "booking_\(bookingRef)")
    ///   - paymentTransactionIdOverride: Payment transaction ID override (optional, defaults to bookingRef)
    /// - Returns: The created transaction (or existing if duplicate)
    /// - Throws: WalletServiceError.insufficientFunds if balance is too low
    @discardableResult
    func applyDebitForBooking(
        amountCents: Int,
        bookingRef: String,
        gymName: String,
        gymId: String? = nil,
        bookingIdOverride: String? = nil,
        paymentTransactionIdOverride: String? = nil
    ) throws -> WalletTransaction {
        // Use overrides for stable booking linkage (extensions link to same booking)
        let stableBookingId = bookingIdOverride ?? "booking_\(bookingRef)"
        let txRef = paymentTransactionIdOverride ?? bookingRef
        
        // Idempotency check: return existing transaction if duplicate
        // This prevents double-charges from double-taps
        // Note: Extensions use unique paymentTransactionIdOverride, so they won't be blocked
        if let existing = existingTransaction(paymentTransactionId: txRef) {
            print("💰 WalletStore.applyDebitForBooking: Duplicate prevented, returning existing tx ref=\(txRef)")
            return existing
        }
        
        // Invariant 5: No negative balances
        guard balanceCents >= amountCents else {
            print("❌ WalletStore.applyDebitForBooking: Insufficient balance (have €\(String(format: "%.2f", balance)), need €\(String(format: "%.2f", Double(amountCents) / 100.0)))")
            throw WalletServiceError.insufficientFunds
        }
        
        // Additional safety: ensure we won't go negative
        guard balanceCents - amountCents >= 0 else {
            print("❌ WalletStore.applyDebitForBooking: Would result in negative balance!")
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
            bookingId: stableBookingId,
            gymId: gymId,
            gymName: gymName,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: txRef,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            status: .completed,
            createdAt: Date(),
            processedAt: Date()
        )
        
        transactions.insert(transaction, at: 0)
        save()
        
        print("💰 WalletStore.applyDebitForBooking: -€\(String(format: "%.2f", Double(amountCents) / 100.0)) for '\(gymName)' bookingId=\(stableBookingId) txRef=\(txRef) → €\(String(format: "%.2f", balanceAfter))")
        validateLedgerIntegrity(context: "applyDebitForBooking")
        
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
        
        // LEDGER FIX: Keep stored balance consistent with ledger
        // Ensures computedBalanceCents == balanceCents after seeding
        balanceCents = computedBalanceCents
        save()
        
        print("💰 WalletStore: Synced balance to €\(String(format: "%.2f", balance)) after seeding")
    }
}
