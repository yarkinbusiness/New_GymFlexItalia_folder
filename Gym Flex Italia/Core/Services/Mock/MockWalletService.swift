//
//  MockWalletService.swift
//  Gym Flex Italia
//
//  Mock implementation of WalletServiceProtocol for demo/testing
//  Uses MockDataStore for consistent gym data and reference codes.
//

import Foundation

/// Mock wallet service that simulates wallet operations with realistic delays
/// All gym references come from MockDataStore for consistency
final class MockWalletService: WalletServiceProtocol {
    
    // MARK: - Mock State (in-memory persistence during session)
    
    /// Current balance in cents
    private var balanceCents: Int = 4500 // €45.00 default
    
    /// List of transactions
    private var mockTransactions: [WalletTransaction]
    
    // MARK: - Initialization
    
    init() {
        // Generate initial mock transactions
        self.mockTransactions = MockWalletService.generateInitialTransactions()
    }
    
    // MARK: - WalletServiceProtocol
    
    func fetchBalance() async throws -> WalletBalance {
        try await simulateNetworkDelay()
        return WalletBalance.eur(cents: balanceCents)
    }
    
    func fetchTransactions() async throws -> [WalletTransaction] {
        try await simulateNetworkDelay()
        return mockTransactions
    }
    
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
        
        // Deterministic failure for testing: amount contains 1337 cents (e.g., €13.37)
        if amountCents == 1337 {
            throw WalletServiceError.topUpFailed("Payment declined. Please try a different amount or contact support.")
        }
        
        // Calculate new balance
        let balanceBefore = Double(balanceCents) / 100.0
        balanceCents += amountCents
        let balanceAfter = Double(balanceCents) / 100.0
        
        // Generate reference code using MockDataStore
        let referenceCode = MockDataStore.makeWalletRef()
        
        // Create new transaction
        let transaction = WalletTransaction(
            id: UUID().uuidString,
            userId: MockDataStore.mockUserId,
            type: .deposit,
            amount: Double(amountCents) / 100.0,
            currency: "EUR",
            description: "Wallet Top-up",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .wallet,
            paymentProvider: "Mock",
            paymentTransactionId: referenceCode,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            status: .completed,
            createdAt: Date(),
            processedAt: Date()
        )
        
        // Insert at beginning of list
        mockTransactions.insert(transaction, at: 0)
        
        return transaction
    }
    
    // MARK: - Helpers
    
    /// Simulates network delay (300-700ms)
    private func simulateNetworkDelay() async throws {
        let delayMs = Int.random(in: 300...700)
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
    }
    
    // MARK: - Mock Data Generation
    
    /// Generates initial list of 15 realistic transactions using gyms from MockDataStore
    private static func generateInitialTransactions() -> [WalletTransaction] {
        var transactions: [WalletTransaction] = []
        var runningBalance: Double = 45.00 // Current balance
        
        let userId = MockDataStore.mockUserId
        let dataStore = MockDataStore.shared
        let gyms = dataStore.gyms
        
        // Generate transactions going back in time
        let calendar = Calendar.current
        var currentDate = Date()
        
        // Transaction 1: Most recent top-up (today)
        let topUp1Amount = 20.00
        transactions.append(WalletTransaction(
            id: "txn_001",
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
            paymentTransactionId: "WL-ABC123",
            balanceBefore: runningBalance - topUp1Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 2: Booking payment (yesterday) - Gym 1
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        let gym1 = gyms[0] // gym_1: FitRoma Center
        let booking1Amount = gym1.pricePerHour
        runningBalance -= topUp1Amount // Go back to previous balance
        transactions.append(WalletTransaction(
            id: "txn_002",
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
            paymentTransactionId: "GF-XY7891",
            balanceBefore: runningBalance + booking1Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 3: Refund (2 days ago) - Gym 2
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        let gym2 = gyms[1] // gym_2: Colosseo Fitness Lab
        let refundAmount = gym2.pricePerHour
        runningBalance += booking1Amount
        transactions.append(WalletTransaction(
            id: "txn_003",
            userId: userId,
            type: .refund,
            amount: refundAmount,
            currency: "EUR",
            description: "Cancelled booking refund - \(gym2.name)",
            bookingId: "booking_cancelled_001",
            gymId: gym2.id,
            gymName: gym2.name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-QW4523",
            balanceBefore: runningBalance - refundAmount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 4: Booking payment (3 days ago) - Gym 3
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        let gym3 = gyms[2] // gym_3: Trastevere Active Hub
        let booking2Amount = gym3.pricePerHour * 2 // 2 hours
        runningBalance -= refundAmount
        transactions.append(WalletTransaction(
            id: "txn_004",
            userId: userId,
            type: .payment,
            amount: booking2Amount,
            currency: "EUR",
            description: "Booking at \(gym3.name)",
            bookingId: "booking_completed_002",
            gymId: gym3.id,
            gymName: gym3.name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-PL8920",
            balanceBefore: runningBalance + booking2Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 5: Top-up (5 days ago)
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let topUp2Amount = 50.00
        runningBalance += booking2Amount
        transactions.append(WalletTransaction(
            id: "txn_005",
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
            paymentTransactionId: "WL-MN5678",
            balanceBefore: runningBalance - topUp2Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 6: Booking (1 week ago) - Gym 4
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let gym4 = gyms[3] // gym_4: Pantheon Power Gym
        let booking3Amount = gym4.pricePerHour
        runningBalance -= topUp2Amount
        transactions.append(WalletTransaction(
            id: "txn_006",
            userId: userId,
            type: .payment,
            amount: booking3Amount,
            currency: "EUR",
            description: "Booking at \(gym4.name)",
            bookingId: "booking_completed_003",
            gymId: gym4.id,
            gymName: gym4.name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-JK3344",
            balanceBefore: runningBalance + booking3Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 7: Bonus credit (8 days ago)
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        let bonusAmount = 5.00
        runningBalance += booking3Amount
        transactions.append(WalletTransaction(
            id: "txn_007",
            userId: userId,
            type: .bonus,
            amount: bonusAmount,
            currency: "EUR",
            description: "Welcome bonus",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: nil,
            paymentProvider: "System",
            paymentTransactionId: "BN-WEL001",
            balanceBefore: runningBalance - bonusAmount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 8: Payment (10 days ago) - Gym 5
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let gym5 = gyms[4] // gym_5: Vatican City Fitness
        let booking4Amount = gym5.pricePerHour
        runningBalance -= bonusAmount
        transactions.append(WalletTransaction(
            id: "txn_008",
            userId: userId,
            type: .payment,
            amount: booking4Amount,
            currency: "EUR",
            description: "Booking at \(gym5.name)",
            bookingId: "booking_completed_004",
            gymId: gym5.id,
            gymName: gym5.name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-RT9087",
            balanceBefore: runningBalance + booking4Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 9: Payment (12 days ago) - Gym 6
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let gym6 = gyms[5] // gym_6: Spanish Steps Strength
        let booking5Amount = gym6.pricePerHour
        runningBalance += booking4Amount
        transactions.append(WalletTransaction(
            id: "txn_009",
            userId: userId,
            type: .payment,
            amount: booking5Amount,
            currency: "EUR",
            description: "Booking at \(gym6.name)",
            bookingId: "booking_completed_005",
            gymId: gym6.id,
            gymName: gym6.name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-UV2211",
            balanceBefore: runningBalance + booking5Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 10: Top-up (2 weeks ago)
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let topUp3Amount = 25.00
        runningBalance += booking5Amount
        transactions.append(WalletTransaction(
            id: "txn_010",
            userId: userId,
            type: .deposit,
            amount: topUp3Amount,
            currency: "EUR",
            description: "Wallet Top-up",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .debitCard,
            paymentProvider: "Mock",
            paymentTransactionId: "WL-EF9012",
            balanceBefore: runningBalance - topUp3Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 11: Payment (16 days ago) - Gym 1
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let booking6Amount = gyms[0].pricePerHour
        runningBalance -= topUp3Amount
        transactions.append(WalletTransaction(
            id: "txn_011",
            userId: userId,
            type: .payment,
            amount: booking6Amount,
            currency: "EUR",
            description: "Booking at \(gyms[0].name)",
            bookingId: "booking_completed_006",
            gymId: gyms[0].id,
            gymName: gyms[0].name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-GH5566",
            balanceBefore: runningBalance + booking6Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 12: Top-up (18 days ago)
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let topUp4Amount = 30.00
        runningBalance += booking6Amount
        transactions.append(WalletTransaction(
            id: "txn_012",
            userId: userId,
            type: .deposit,
            amount: topUp4Amount,
            currency: "EUR",
            description: "Wallet Top-up",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .creditCard,
            paymentProvider: "Mock",
            paymentTransactionId: "WL-CD3456",
            balanceBefore: runningBalance - topUp4Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 13: Pending transaction (20 days ago, still pending)
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let pendingAmount = 15.00
        transactions.append(WalletTransaction(
            id: "txn_013",
            userId: userId,
            type: .deposit,
            amount: pendingAmount,
            currency: "EUR",
            description: "Wallet Top-up (Processing)",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .creditCard,
            paymentProvider: "Mock",
            paymentTransactionId: "WL-PEND01",
            balanceBefore: runningBalance - topUp4Amount,
            balanceAfter: runningBalance - topUp4Amount + pendingAmount,
            status: .pending,
            createdAt: currentDate,
            processedAt: nil
        ))
        
        // Transaction 14: Payment (22 days ago) - Gym 3
        currentDate = calendar.date(byAdding: .day, value: -2, to: currentDate)!
        let booking7Amount = gyms[2].pricePerHour
        runningBalance -= topUp4Amount
        transactions.append(WalletTransaction(
            id: "txn_014",
            userId: userId,
            type: .payment,
            amount: booking7Amount,
            currency: "EUR",
            description: "Booking at \(gyms[2].name)",
            bookingId: "booking_completed_007",
            gymId: gyms[2].id,
            gymName: gyms[2].name,
            paymentMethod: .wallet,
            paymentProvider: nil,
            paymentTransactionId: "GF-IJ7788",
            balanceBefore: runningBalance + booking7Amount,
            balanceAfter: runningBalance,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        // Transaction 15: Initial deposit (1 month ago)
        currentDate = calendar.date(byAdding: .day, value: -8, to: currentDate)!
        let initialAmount = 50.00
        runningBalance += booking7Amount
        transactions.append(WalletTransaction(
            id: "txn_015",
            userId: userId,
            type: .deposit,
            amount: initialAmount,
            currency: "EUR",
            description: "Initial wallet deposit",
            bookingId: nil,
            gymId: nil,
            gymName: nil,
            paymentMethod: .creditCard,
            paymentProvider: "Mock",
            paymentTransactionId: "WL-INIT01",
            balanceBefore: 0,
            balanceAfter: initialAmount,
            status: .completed,
            createdAt: currentDate,
            processedAt: currentDate
        ))
        
        return transactions
    }
}
