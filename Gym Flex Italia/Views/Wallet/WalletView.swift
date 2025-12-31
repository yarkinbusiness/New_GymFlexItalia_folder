//
//  WalletFullView.swift
//  Gym Flex Italia
//
//  Complete wallet screen with balance, transactions list, and top-up
//

import SwiftUI

/// Full wallet screen with balance and transaction history
struct WalletFullView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    
    @StateObject private var viewModel = WalletFullViewModel()
    
    @State private var showTopUpSheet = false
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else {
                mainContent
            }
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    DemoTapLogger.log("Wallet.TopUp.Open")
                    showTopUpSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Top Up")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
                }
            }
        }
        .sheet(isPresented: $showTopUpSheet) {
            topUpSheet
        }
        .task {
            await viewModel.load(using: appContainer.walletService)
        }
        .refreshable {
            await viewModel.refresh(using: appContainer.walletService)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading wallet...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Error Banner
                if let error = viewModel.errorMessage {
                    InlineErrorBanner(
                        message: error,
                        type: .error,
                        onDismiss: { viewModel.clearError() }
                    )
                    .padding(.horizontal, Spacing.lg)
                }
                
                // Success Banner
                if let success = viewModel.topUpSuccessMessage {
                    InlineErrorBanner(
                        message: success,
                        type: .success,
                        onDismiss: { viewModel.clearSuccess() }
                    )
                    .padding(.horizontal, Spacing.lg)
                }
                
                // Balance Card
                balanceCard
                
                // Quick Actions
                quickActions
                
                // Transactions List
                transactionsSection
            }
            .padding(.vertical, Spacing.lg)
        }
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
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
                
                Text(String(format: "%.2f", viewModel.balance?.amount ?? 0))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(AppColors.textHigh)
            }
            
            Text(viewModel.balance?.currency ?? "EUR")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadii.xl)
                .fill(AppGradients.primary.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadii.xl)
                        .stroke(AppColors.brand.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: Spacing.md) {
            QuickActionButton(
                icon: "plus.circle.fill",
                label: "Add Funds",
                color: .green
            ) {
                DemoTapLogger.log("Wallet.QuickAction.AddFunds")
                showTopUpSheet = true
            }
            
            QuickActionButton(
                icon: "clock.arrow.circlepath",
                label: "History",
                color: .blue
            ) {
                DemoTapLogger.log("Wallet.QuickAction.History")
                // Already showing history below
            }
            
            QuickActionButton(
                icon: "arrow.up.circle.fill",
                label: "Send",
                color: .orange
            ) {
                DemoTapLogger.logNoOp("Wallet.QuickAction.Send")
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - Transactions Section
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Transactions")
                .font(AppFonts.h5)
                .foregroundColor(AppColors.textHigh)
                .padding(.horizontal, Spacing.lg)
            
            if viewModel.hasTransactions {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction) {
                            DemoTapLogger.log("Wallet.Transaction.Tap", context: "id: \(transaction.id)")
                            router.pushWalletTransactionDetail(transactionId: transaction.id)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            } else {
                emptyTransactionsView
            }
        }
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textDim)
            
            Text("No transactions yet")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
            
            Text("Add funds to get started")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textDim.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    // MARK: - Top Up Sheet
    
    private var topUpSheet: some View {
        TopUpSheetView(isPresented: $showTopUpSheet, viewModel: viewModel)
    }
}


// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textHigh)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: WalletTransaction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: transaction.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textHigh)
                        .lineLimit(1)
                    
                    HStack(spacing: Spacing.xs) {
                        Text(formattedDate)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textDim)
                        
                        if transaction.status != .completed {
                            Text("•")
                                .foregroundColor(AppColors.textDim)
                            Text(transaction.status.displayName)
                                .font(AppFonts.caption)
                                .foregroundColor(statusColor)
                        }
                    }
                }
                
                Spacer()
                
                // Amount
                Text(formattedAmount)
                    .font(AppFonts.h5)
                    .foregroundColor(transaction.type.isPositive ? .green : AppColors.textHigh)
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textDim)
            }
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md)
        }
        .buttonStyle(.plain)
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .deposit, .bonus:
            return .green
        case .refund:
            return .blue
        case .payment, .withdrawal:
            return .orange
        case .penalty:
            return .red
        }
    }
    
    private var statusColor: Color {
        switch transaction.status {
        case .completed:
            return .green
        case .pending, .processing:
            return .orange
        case .failed, .cancelled:
            return .red
        case .refunded:
            return .blue
        }
    }
    
    private var formattedAmount: String {
        let prefix = transaction.type.isPositive ? "+" : ""
        return "\(prefix)€\(String(format: "%.2f", abs(transaction.amount)))"
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: transaction.createdAt, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        WalletFullView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
