//
//  WalletViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import Foundation
import Combine
import PassKit

/// ViewModel for wallet management and top-up
@MainActor
final class WalletViewModel: ObservableObject {
    
    // Use shared wallet store for balance - observe it directly
    var balance: Double {
        walletStore.balance
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Top-up state
    @Published var selectedAmount: Double?
    @Published var customAmount: String = ""
    @Published var selectedPaymentMethod: PaymentMethod = .applePay
    @Published var isProcessingPayment = false
    
    // Card payment form state
    @Published var cardNumber: String = ""
    @Published var cardExpiry: String = ""
    @Published var cardCVV: String = ""
    @Published var cardholderName: String = ""
    
    // Apple Pay
    @Published var canUseApplePay: Bool = false
    
    private let walletService = WalletService.shared
    private let walletStore = WalletStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Predefined top-up amounts
    let predefinedAmounts: [Double] = [10.0, 25.0, 50.0, 100.0]
    
    init() {
        checkApplePayAvailability()
        loadBalance()
        
        // Observe wallet store changes to trigger view updates
        walletStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Balance
    func loadBalance() {
        Task {
            isLoading = true
            errorMessage = nil
            
            // Load balance through shared store
            await walletStore.loadBalance()
            
            isLoading = false
        }
    }
    
    // MARK: - Apple Pay
    func checkApplePayAvailability() {
        canUseApplePay = PKPaymentAuthorizationController.canMakePayments()
    }
    
    var topUpAmount: Double {
        if let selected = selectedAmount {
            return selected
        } else if !customAmount.isEmpty, let custom = Double(customAmount) {
            return custom
        }
        return 0
    }
    
    var isValidAmount: Bool {
        topUpAmount >= 5.0 && topUpAmount <= 1000.0
    }
    
    // MARK: - Top-Up
    func processTopUp() async {
        guard isValidAmount else {
            errorMessage = "Amount must be between €5 and €1000"
            return
        }
        
        isProcessingPayment = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Mock payment processing for now
            // In production, this would:
            // 1. Process payment with Apple Pay or card
            // 2. Call walletService.addFunds()
            // 3. Update balance
            
            try await Task.sleep(nanoseconds: 1_500_000_000) // Simulate payment processing
            
            // Mock successful top-up
            if FeatureFlags.shared.isDemoMode {
                // Simulate adding funds - update shared store
                walletStore.addFunds(topUpAmount)
                successMessage = "Successfully added €\(String(format: "%.2f", topUpAmount)) to your wallet!"
            } else {
                let transaction = try await walletService.addFunds(
                    amount: topUpAmount,
                    paymentMethod: selectedPaymentMethod
                )
                // Update shared store with new balance
                walletStore.updateBalance(transaction.balanceAfter)
                successMessage = "Successfully added €\(String(format: "%.2f", topUpAmount)) to your wallet!"
            }
            
            // Reset form
            selectedAmount = nil
            customAmount = ""
            cardNumber = ""
            cardExpiry = ""
            cardCVV = ""
            cardholderName = ""
            
        } catch {
            errorMessage = "Payment failed: \(error.localizedDescription)"
        }
        
        isProcessingPayment = false
    }
    
    // MARK: - Apple Pay Payment Request
    @MainActor
    func createApplePayRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.gymflex.italia" // Replace with real merchant ID
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "IT"
        request.currencyCode = "EUR"
        
        // Payment summary
        let paymentSummaryItem = PKPaymentSummaryItem(
            label: "GymFlex Italia Wallet Top-Up",
            amount: NSDecimalNumber(value: topUpAmount)
        )
        request.paymentSummaryItems = [paymentSummaryItem]
        
        return request
    }
    
    // MARK: - Card Validation
    var isCardFormValid: Bool {
        guard !cardNumber.isEmpty,
              !cardExpiry.isEmpty,
              !cardCVV.isEmpty,
              !cardholderName.isEmpty else {
            return false
        }
        
        // Basic validation (in production, use proper card validation library)
        let cleanedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        return cleanedCardNumber.count >= 13 && cleanedCardNumber.count <= 19 &&
               cardExpiry.count == 5 && // MM/YY format
               cardCVV.count >= 3 && cardCVV.count <= 4
    }
    
    // MARK: - Formatting Helpers
    func formatCardNumber(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        
        return String(formatted.prefix(19)) // Max 16 digits + 3 spaces
    }
    
    func formatExpiry(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "/", with: "")
        var formatted = ""
        
        for (index, char) in cleaned.enumerated() {
            if index == 2 {
                formatted += "/"
            }
            formatted.append(char)
        }
        
        return String(formatted.prefix(5)) // MM/YY format
    }
}

