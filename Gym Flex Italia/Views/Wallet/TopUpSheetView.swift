//
//  TopUpSheetView.swift
//  Gym Flex Italia
//
//  Top-up amount entry sheet
//

import SwiftUI

/// Sheet for entering top-up amount
struct TopUpSheetView: View {
    
    @Environment(\.appContainer) private var appContainer
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: WalletFullViewModel
    
    @State private var amountText = ""
    @State private var errorMessage: String?
    
    private let quickAmounts = [10, 25, 50, 100]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Error
                        if let error = errorMessage {
                            InlineErrorBanner(
                                message: error,
                                type: .error,
                                onDismiss: { errorMessage = nil }
                            )
                        }
                        
                        // Amount Input Card
                        amountInputCard
                        
                        // Quick Amount Buttons
                        quickAmountButtons
                        
                        // Min/Max info
                        Text("Min: €5.00 • Max: €200.00")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textDim)
                        
                        Spacer(minLength: Spacing.xxl)
                        
                        // Confirm Button
                        confirmButton
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Top Up Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Amount Input Card
    
    private var amountInputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Amount (€)")
                .font(AppFonts.label)
                .foregroundColor(AppColors.textDim)
            
            HStack {
                Text("€")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(AppColors.textDim)
                
                TextField("10.00", text: $amountText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.textHigh)
                    .keyboardType(.decimalPad)
            }
            .padding(Spacing.lg)
            .glassBackground(cornerRadius: CornerRadii.lg)
        }
    }
    
    // MARK: - Quick Amount Buttons
    
    private var quickAmountButtons: some View {
        HStack(spacing: Spacing.md) {
            ForEach(quickAmounts, id: \.self) { amount in
                QuickAmountButton(
                    amount: amount,
                    isSelected: amountText == "\(amount)",
                    action: { amountText = "\(amount)" }
                )
            }
        }
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button {
            DemoTapLogger.log("Wallet.TopUp.Confirm")
            confirmTopUp()
        } label: {
            HStack {
                if viewModel.isTopUpLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Add Funds")
                        .font(AppFonts.label)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(confirmButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
        }
        .disabled(!isValidAmount || viewModel.isTopUpLoading)
    }
    
    @ViewBuilder
    private var confirmButtonBackground: some View {
        if isValidAmount {
            AppGradients.primary
        } else {
            AppColors.secondary
        }
    }
    
    // MARK: - Helpers
    
    private var isValidAmount: Bool {
        guard let cents = parseAmountCents() else { return false }
        return cents >= 500 && cents <= 20000
    }
    
    private func parseAmountCents() -> Int? {
        let cleaned = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        
        guard let doubleValue = Double(cleaned) else { return nil }
        return Int(doubleValue * 100)
    }
    
    private func confirmTopUp() {
        guard let amountCents = parseAmountCents() else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        errorMessage = nil
        
        Task {
            let success = await viewModel.topUp(amountCents: amountCents, using: appContainer.walletService)
            
            if success {
                amountText = ""
                isPresented = false
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("€\(amount)")
                .font(AppFonts.label)
                .foregroundColor(isSelected ? .white : AppColors.textHigh)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(backgroundView)
                .glassBackground(cornerRadius: CornerRadii.md, opacity: isSelected ? 0 : 0.3)
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            AppGradients.primary
        } else {
            Color.clear
        }
    }
}
