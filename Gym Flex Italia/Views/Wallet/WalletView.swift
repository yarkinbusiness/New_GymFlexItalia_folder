//
//  WalletView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import SwiftUI
import PassKit
import UIKit

/// Wallet top-up modal view
struct WalletView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = WalletViewModel()
    @State private var showCardForm = false
    @State private var paymentDelegate: PaymentDelegate?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Balance Display
                        balanceSection
                        
                        // Top-Up Amount Selection
                        amountSelectionSection
                        
                        // Payment Method Selection
                        paymentMethodSection
                        
                        // Card Form (if selected)
                        if showCardForm && viewModel.selectedPaymentMethod == .creditCard {
                            cardFormSection
                        }
                        
                        // Top-Up Button
                        topUpButton
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textHigh)
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Success", isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { _ in viewModel.successMessage = nil }
            )) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
        }
    }
    
    // MARK: - Balance Section
    private var balanceSection: some View {
        VStack(spacing: Spacing.md) {
            Text("Current Balance")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textDim)
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("€")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(AppColors.textHigh)
                
                Text(String(format: "%.2f", viewModel.balance))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.textHigh)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassBackground(cornerRadius: CornerRadii.xl, opacity: 0.4, blur: 25)
    }
    
    // MARK: - Amount Selection Section
    private var amountSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Select Amount")
                .font(AppFonts.h5)
                .foregroundColor(AppColors.textHigh)
            
            // Predefined amounts
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(viewModel.predefinedAmounts, id: \.self) { amount in
                    AmountButton(
                        amount: amount,
                        isSelected: viewModel.selectedAmount == amount
                    ) {
                        viewModel.selectedAmount = amount
                        viewModel.customAmount = ""
                    }
                }
            }
            
            // Custom amount
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Or enter custom amount")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textDim)
                
                HStack {
                    Text("€")
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.textDim)
                    
                    TextField("0.00", text: $viewModel.customAmount)
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.textHigh)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.customAmount) { _, newValue in
                            // Clear selected amount when typing custom
                            if !newValue.isEmpty {
                                viewModel.selectedAmount = nil
                            }
                        }
                }
                .padding(Spacing.md)
                .glassBackground(cornerRadius: CornerRadii.md, opacity: 0.3, blur: 18)
            }
        }
    }
    
    // MARK: - Payment Method Section
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Payment Method")
                .font(AppFonts.h5)
                .foregroundColor(AppColors.textHigh)
            
            VStack(spacing: Spacing.sm) {
                // Apple Pay Button
                if viewModel.canUseApplePay {
                    ApplePayButton(
                        isSelected: viewModel.selectedPaymentMethod == .applePay
                    ) {
                        viewModel.selectedPaymentMethod = .applePay
                        showCardForm = false
                    }
                }
                
                // Credit Card Button
                CardPaymentButton(
                    isSelected: viewModel.selectedPaymentMethod == .creditCard
                ) {
                    viewModel.selectedPaymentMethod = .creditCard
                    showCardForm = true
                }
            }
        }
    }
    
    // MARK: - Card Form Section
    private var cardFormSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Card Details")
                .font(AppFonts.h5)
                .foregroundColor(AppColors.textHigh)
            
            VStack(spacing: Spacing.md) {
                // Card Number
                GlassInputField(
                    title: "Card Number",
                    placeholder: "1234 5678 9012 3456",
                    text: Binding(
                        get: { viewModel.cardNumber },
                        set: { viewModel.cardNumber = viewModel.formatCardNumber($0) }
                    ),
                    icon: "creditcard.fill",
                    keyboardType: .numberPad
                )
                
                // Expiry and CVV
                HStack(spacing: Spacing.md) {
                    GlassInputField(
                        title: "Expiry",
                        placeholder: "MM/YY",
                        text: Binding(
                            get: { viewModel.cardExpiry },
                            set: { viewModel.cardExpiry = viewModel.formatExpiry($0) }
                        ),
                        icon: "calendar",
                        keyboardType: .numberPad
                    )
                    
                    GlassInputField(
                        title: "CVV",
                        placeholder: "123",
                        text: $viewModel.cardCVV,
                        icon: "lock.fill",
                        isSecure: true,
                        keyboardType: .numberPad
                    )
                }
                
                // Cardholder Name
                GlassInputField(
                    title: "Cardholder Name",
                    placeholder: "John Doe",
                    text: $viewModel.cardholderName,
                    icon: "person.fill"
                )
            }
        }
        .padding(Spacing.md)
        .glassBackground(cornerRadius: CornerRadii.lg, opacity: 0.3, blur: 18)
    }
    
    // MARK: - Top-Up Button
    private var topUpButton: some View {
        Button {
            Task {
                if viewModel.selectedPaymentMethod == .applePay {
                    // In mock mode, skip Apple Pay presentation
                    if AppConfig.API.useMocks {
                        await viewModel.processTopUp()
                    } else {
                        await processApplePay()
                    }
                } else {
                    await viewModel.processTopUp()
                }
            }
        } label: {
            HStack {
                if viewModel.isProcessingPayment {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Add Funds")
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                Group {
                    if viewModel.isValidAmount && !viewModel.isProcessingPayment {
                        AppGradients.primary
                    } else {
                        AppColors.secondary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous))
            .shadow(
                color: viewModel.isValidAmount ? AppColors.brand.opacity(0.4) : Color.clear,
                radius: 20,
                x: 0,
                y: 10
            )
        }
        .disabled(!viewModel.isValidAmount || viewModel.isProcessingPayment)
        .opacity(viewModel.isValidAmount ? 1.0 : 0.6)
    }
    
    // MARK: - Apple Pay Processing
    private func processApplePay() async {
        let request = await viewModel.createApplePayRequest()
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        
        let delegate = PaymentDelegate { result in
            Task { @MainActor [weak viewModel] in
                guard let viewModel = viewModel else { return }
                switch result {
case .success:
                    await viewModel.processTopUp()
                case .failure(let error):
                    viewModel.errorMessage = "Apple Pay failed: \(error.localizedDescription)"
                }
            }
        }
        
        // Retain delegate in state to prevent deallocation
        paymentDelegate = delegate
        controller.delegate = delegate
        
        controller.present { success in
            Task { @MainActor [weak viewModel] in
                guard let viewModel = viewModel else { return }
                if !success {
                    viewModel.errorMessage = "Unable to present Apple Pay"
                }
            }
        }
    }
}

// MARK: - Amount Button
struct AmountButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text("€\(String(format: "%.0f", amount))")
                    .font(AppFonts.h5)
                    .foregroundColor(isSelected ? .white : AppColors.textHigh)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                Group {
                    if isSelected {
                        AppGradients.primary
                    } else {
                        Color.clear
                    }
                }
            )
            .glassBackground(cornerRadius: CornerRadii.md, opacity: isSelected ? 0 : 0.3)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.md)
                    .stroke(
                        isSelected ? Color.clear : AppColors.border.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Apple Pay Button
struct ApplePayButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Apple Pay")
                    .font(AppFonts.label)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.brand)
                }
            }
            .foregroundColor(isSelected ? AppColors.textHigh : AppColors.textDim)
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md, opacity: isSelected ? 0.4 : 0.3)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.md)
                    .stroke(
                        isSelected ? AppColors.brand : AppColors.border.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card Payment Button
struct CardPaymentButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                
                Text("Debit/Credit Card")
                    .font(AppFonts.label)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.brand)
                }
            }
            .foregroundColor(isSelected ? AppColors.textHigh : AppColors.textDim)
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md, opacity: isSelected ? 0.4 : 0.3)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.md)
                    .stroke(
                        isSelected ? AppColors.brand : AppColors.border.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Glass Input Field
// GlassInputField is now in Views/Shared/GlassInputField.swift

// MARK: - Payment Delegate
class PaymentDelegate: NSObject, PKPaymentAuthorizationControllerDelegate {
    let completion: (Result<Void, Error>) -> Void
    
    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }
    
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // In production, send payment token to backend for processing
        // For now, simulate success
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        self.completion(.success(()))
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}

#Preview {
    WalletView()
}

