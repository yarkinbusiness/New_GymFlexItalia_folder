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
    
    /// Single source of truth for wallet data
    @ObservedObject private var walletStore = WalletStore.shared
    
    @StateObject private var viewModel = WalletFullViewModel()
    
    @State private var showTopUpSheet = false
    @State private var showSendSheet = false
    @State private var hasLoadAttempted = false
    @State private var containerStatus: String = "unknown"
    
    // Balance change highlight
    @State private var balanceHighlight = false
    @State private var previousBalanceCents: Int = -1 // -1 = not yet initialized
    @State private var hasBalanceInitialized = false
    
    // Reduce Motion support
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Layered background (surface0 = deepest layer)
            theme.colors.surface0
                .ignoresSafeArea()
            
            if viewModel.isLoading && !hasLoadAttempted {
                loadingView
            } else if let errorMessage = viewModel.errorMessage, viewModel.balance == nil {
                // Show full error state if we have no data
                errorStateView(errorMessage)
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
        .sheet(isPresented: $showSendSheet) {
            SendMoneySheetView()
        }
        .task {
            await loadWallet()
        }
        .onAppear {
            // Validate container on appear
            validateContainer()
        }
        .refreshable {
            await loadWallet()
        }
    }
    
    // MARK: - Wallet Loading
    
    private func loadWallet() async {
        print("💳 WALLET: entering WalletFullView.loadWallet()")
        print("💳 WALLET: walletService=\(type(of: appContainer.walletService))")
        print("💳 WALLET: containerStatus=\(containerStatus)")
        print("💳 WALLET: calling load()...")
        
        hasLoadAttempted = true
        
        await viewModel.load(using: appContainer.walletService)
        
        if let error = viewModel.errorMessage {
            print("❌ WALLET: error=\(error)")
        } else {
            print("✅ WALLET: loaded balance=\(String(describing: viewModel.balance?.amount)) transactions=\(viewModel.transactions.count)")
        }
    }
    
    private func validateContainer() {
        // Check if appContainer is properly injected
        let serviceType = String(describing: type(of: appContainer.walletService))
        containerStatus = serviceType.isEmpty ? "NOT_INJECTED" : serviceType
        print("💳 WALLET: onAppear containerStatus=\(containerStatus)")
    }
    
    // MARK: - Error State View
    
    private func errorStateView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            // Error title
            Text("Unable to Load Wallet")
                .font(AppFonts.h4)
                .foregroundColor(AppColors.textHigh)
            
            // Error message
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            // Retry button
            Button {
                DemoTapLogger.log("Wallet.Retry")
                Task {
                    await loadWallet()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(AppFonts.label)
                .foregroundColor(.white)
                .frame(maxWidth: 200)
                .padding(.vertical, Spacing.md)
                .background(AppGradients.primary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
            
            // DEBUG diagnostics
            #if DEBUG
            diagnosticsBanner
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Debug Diagnostics Banner
    
    #if DEBUG
    private var diagnosticsBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("DEBUG DIAGNOSTICS")
                .font(AppFonts.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Group {
                Text("• appContainer injected: \(containerStatus != "NOT_INJECTED" ? "YES" : "NO")")
                Text("• walletService type: \(containerStatus)")
                Text("• balance: \(viewModel.balance?.formattedBalance ?? "nil")")
                Text("• transactions count: \(viewModel.transactions.count)")
                Text("• errorMessage: \(viewModel.errorMessage ?? "nil")")
                Text("• hasLoadAttempted: \(hasLoadAttempted ? "YES" : "NO")")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.orange)
        }
        .padding(Spacing.md)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
        .padding(.top, Spacing.lg)
    }
    #endif
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading wallet...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
            
            #if DEBUG
            Text("walletService: \(containerStatus)")
                .font(AppFonts.caption)
                .foregroundColor(.orange)
            #endif
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // DEBUG: Success diagnostics banner
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEBUG: Wallet Loaded ✅ (using WalletStore)")
                            .font(AppFonts.caption)
                            .foregroundColor(.green)
                        Text("balance: \(walletStore.formattedBalance) | tx: \(walletStore.transactions.count) | persisted: ✅")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.sm))
                    .padding(.horizontal, Spacing.lg)
                    #endif
                    
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
                    
                    // Quick Actions (pass scrollProxy for History)
                    quickActions(scrollProxy: scrollProxy)
                    
                    // Transactions List
                    transactionsSection
                        .id("transactions_section") // Anchor for History scroll
                }
                .padding(.vertical, Spacing.lg)
            }
        }
    }
    
    // MARK: - Balance Card
    
    @Environment(\.gfTheme) private var theme
    
    private var balanceCard: some View {
        GFCard(padding: GFSpacing.xl) {
            VStack(spacing: GFSpacing.md) {
                Text("Current Balance")
                    .gfCaption(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                HStack(alignment: .firstTextBaseline, spacing: GFSpacing.xs) {
                    Text("€")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    // Animated balance with smooth transitions (respects Reduce Motion)
                    GFNumberText(
                        value: walletStore.balance,
                        formatStyle: .decimal(places: 2),
                        font: .system(size: 56, weight: .bold),
                        color: theme.colors.textPrimary
                    )
                }
                
                Text(walletStore.currency)
                    .gfCaption()
                    .foregroundColor(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GFSpacing.lg)
        }
        .overlay(
            RoundedRectangle(cornerRadius: GFCorners.card)
                .stroke(
                    balanceHighlight ? theme.colors.success.opacity(0.6) : theme.colors.primary.opacity(0.2),
                    lineWidth: balanceHighlight ? 2 : 1
                )
                // Only animate if Reduce Motion is OFF
                .animation(reduceMotion ? nil : GFMotion.confirm, value: balanceHighlight)
        )
        .padding(.horizontal, Spacing.lg)
        .onChange(of: walletStore.balanceCents) { oldValue, newValue in
            // Guard: Skip if this is the initial load
            guard hasBalanceInitialized else {
                hasBalanceInitialized = true
                previousBalanceCents = newValue
                return
            }
            
            // Guard: Skip if no actual change
            guard oldValue != newValue else { return }
            
            // Only highlight and haptic on POSITIVE balance changes (top-up, not refund/debit)
            let isPositiveChange = newValue > oldValue
            
            if isPositiveChange {
                // Trigger highlight (static if Reduce Motion)
                if reduceMotion {
                    // Static highlight - no animation
                    balanceHighlight = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        balanceHighlight = false
                    }
                } else {
                    // Animated highlight
                    balanceHighlight = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        balanceHighlight = false
                    }
                }
                
                // Success haptic (debounced via HapticGate)
                HapticGate.successOnce(key: "wallet_topup_success")
            }
            
            previousBalanceCents = newValue
        }
        .onAppear {
            // Initialize with current balance
            if !hasBalanceInitialized {
                previousBalanceCents = walletStore.balanceCents
                hasBalanceInitialized = true
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private func quickActions(scrollProxy: ScrollViewProxy) -> some View {
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
                // Scroll to transactions section
                if reduceMotion {
                    scrollProxy.scrollTo("transactions_section", anchor: .top)
                } else {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        scrollProxy.scrollTo("transactions_section", anchor: .top)
                    }
                }
            }
            
            QuickActionButton(
                icon: "arrow.up.circle.fill",
                label: "Send",
                color: .orange
            ) {
                DemoTapLogger.log("Wallet.QuickAction.Send")
                showSendSheet = true
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
            
            // Use walletStore directly for real-time transactions
            if walletStore.hasTransactions {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(walletStore.transactions) { transaction in
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
