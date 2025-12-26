//
//  WalletStore.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import Foundation
import Combine

/// Shared wallet state manager for real-time balance updates across the app
@MainActor
final class WalletStore: ObservableObject {
    
    static let shared = WalletStore()
    
    @Published var balance: Double = 0.0
    @Published var isLoading: Bool = false
    
    private let walletService = WalletService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load initial balance
        Task {
            await loadBalance()
        }
    }
    
    // MARK: - Load Balance
    func loadBalance() async {
        isLoading = true
        
        do {
            // For demo mode, use mock balance
            if FeatureFlags.shared.isDemoMode {
                balance = 12.50
            } else {
                balance = try await walletService.fetchBalance()
            }
        } catch {
            print("Failed to load wallet balance: \(error)")
            // Fallback for demo
            if FeatureFlags.shared.isDemoMode {
                balance = 12.50
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Update Balance
    func updateBalance(_ newBalance: Double) {
        balance = newBalance
    }
    
    // MARK: - Add Funds (called after successful top-up)
    func addFunds(_ amount: Double) {
        balance += amount
    }
    
    // MARK: - Refresh Balance
    func refreshBalance() async {
        await loadBalance()
    }
}

