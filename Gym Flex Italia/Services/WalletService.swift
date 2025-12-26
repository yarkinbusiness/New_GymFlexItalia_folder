//
//  WalletService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Wallet and transaction management service (Phase 2/3)
final class WalletService {
    
    static let shared = WalletService()
    
    private let baseURL = AppConfig.API.baseURL
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Fetch Wallet Balance
    func fetchBalance() async throws -> Double {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
            return 125.50 // Mock balance
        }
        
        guard let token = authService.getStoredToken() else {
            throw WalletError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/wallet/balance")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WalletError.fetchBalanceFailed
        }
        
        let balanceResponse = try JSONDecoder().decode(BalanceResponse.self, from: data)
        return balanceResponse.balance
    }
    
    // MARK: - Fetch Transactions
    func fetchTransactions(limit: Int = 50, offset: Int = 0) async throws -> [WalletTransaction] {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            return [
                WalletTransaction(
                    id: "txn_001",
                    userId: "user_123",
                    type: .deposit,
                    amount: 50.00,
                    currency: "EUR",
                    description: "Top up via Credit Card",
                    paymentMethod: .creditCard,
                    balanceBefore: 75.50,
                    balanceAfter: 125.50,
                    status: .completed,
                    createdAt: Date().addingTimeInterval(-86400 * 2)
                ),
                WalletTransaction(
                    id: "txn_002",
                    userId: "user_123",
                    type: .payment,
                    amount: -8.50,
                    currency: "EUR",
                    description: "Booking at Flex Gym Roma Termini",
                    paymentMethod: .wallet,
                    balanceBefore: 84.00,
                    balanceAfter: 75.50,
                    status: .completed,
                    createdAt: Date().addingTimeInterval(-3600)
                )
            ]
        }
        
        guard let token = authService.getStoredToken() else {
            throw WalletError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/wallet/transactions")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = components.url else {
            throw WalletError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WalletError.fetchTransactionsFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WalletTransaction].self, from: data)
    }
    
    // MARK: - Add Funds (Phase 3)
    func addFunds(amount: Double, paymentMethod: PaymentMethod) async throws -> WalletTransaction {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            return WalletTransaction(
                id: "txn_mock_\(Int.random(in: 1000...9999))",
                userId: "user_123",
                type: .deposit,
                amount: amount,
                currency: "EUR",
                description: "Top up via \(paymentMethod.rawValue)",
                paymentMethod: paymentMethod,
                balanceBefore: 125.50,
                balanceAfter: 125.50 + amount,
                status: .completed,
                createdAt: Date()
            )
        }
        
        guard let token = authService.getStoredToken() else {
            throw WalletError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/wallet/add-funds")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "amount": amount,
            "payment_method": paymentMethod.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WalletError.addFundsFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WalletTransaction.self, from: data)
    }
    
    // MARK: - Process Payment
    func processPayment(amount: Double, bookingId: String) async throws -> WalletTransaction {
        guard let token = authService.getStoredToken() else {
            throw WalletError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/wallet/process-payment")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "amount": amount,
            "booking_id": bookingId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WalletError.paymentFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WalletTransaction.self, from: data)
    }
    
    // MARK: - Request Refund
    func requestRefund(transactionId: String, reason: String?) async throws -> WalletTransaction {
        guard let token = authService.getStoredToken() else {
            throw WalletError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/wallet/transactions/\(transactionId)/refund")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let reason = reason {
            let body: [String: Any] = ["reason": reason]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WalletError.refundFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WalletTransaction.self, from: data)
    }
}

// MARK: - Balance Response
struct BalanceResponse: Codable {
    let balance: Double
    let currency: String
}

// MARK: - Wallet Errors
enum WalletError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case fetchBalanceFailed
    case fetchTransactionsFailed
    case addFundsFailed
    case paymentFailed
    case insufficientFunds
    case refundFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .fetchBalanceFailed:
            return "Failed to fetch balance"
        case .fetchTransactionsFailed:
            return "Failed to fetch transactions"
        case .addFundsFailed:
            return "Failed to add funds"
        case .paymentFailed:
            return "Payment failed"
        case .insufficientFunds:
            return "Insufficient funds"
        case .refundFailed:
            return "Refund request failed"
        }
    }
}

