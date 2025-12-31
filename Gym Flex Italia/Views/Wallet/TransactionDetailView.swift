//
//  TransactionDetailView.swift
//  Gym Flex Italia
//
//  Detail/receipt view for a wallet transaction
//

import SwiftUI

/// Transaction detail/receipt screen
struct TransactionDetailView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    
    let transactionId: String
    
    /// Optional: pass transaction directly to avoid re-fetching
    var preloadedTransaction: WalletTransaction?
    
    @State private var transaction: WalletTransaction?
    @State private var isLoading = true
    @State private var showCopiedAlert = false
    
    var body: some View {
        ZStack {
            AppGradients.background
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if let txn = transaction ?? preloadedTransaction {
                transactionContent(txn)
            } else {
                errorView
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTransaction()
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("Reference code copied to clipboard")
        }
    }
    
    // MARK: - Transaction Content
    
    private func transactionContent(_ txn: WalletTransaction) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Status Header
                statusHeader(txn)
                
                // Amount Card
                amountCard(txn)
                
                // Details List
                detailsList(txn)
                
                // Actions
                actionsSection(txn)
            }
            .padding(Spacing.lg)
        }
    }
    
    // MARK: - Status Header
    
    private func statusHeader(_ txn: WalletTransaction) -> some View {
        VStack(spacing: Spacing.md) {
            // Status Icon
            Image(systemName: txn.status.icon)
                .font(.system(size: 48))
                .foregroundColor(statusColor(txn.status))
            
            // Status Text
            Text(txn.status.displayName)
                .font(AppFonts.h4)
                .foregroundColor(statusColor(txn.status))
            
            // Type
            HStack(spacing: Spacing.xs) {
                Image(systemName: txn.type.icon)
                    .font(.system(size: 14))
                Text(txn.type.displayName)
                    .font(AppFonts.caption)
            }
            .foregroundColor(AppColors.textDim)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(AppColors.secondary.opacity(0.3))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    // MARK: - Amount Card
    
    private func amountCard(_ txn: WalletTransaction) -> some View {
        VStack(spacing: Spacing.sm) {
            Text(txn.type.isPositive ? "Received" : "Paid")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textDim)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(txn.type.isPositive ? "+" : "-")
                    .font(.system(size: 32, weight: .bold))
                Text("€")
                    .font(.system(size: 28, weight: .semibold))
                Text(String(format: "%.2f", abs(txn.amount)))
                    .font(.system(size: 48, weight: .bold))
            }
            .foregroundColor(txn.type.isPositive ? .green : AppColors.textHigh)
            
            Text(txn.currency)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassBackground(cornerRadius: CornerRadii.xl)
    }
    
    // MARK: - Details List
    
    private func detailsList(_ txn: WalletTransaction) -> some View {
        VStack(spacing: 0) {
            // Description
            TransactionDetailRow(label: "Description", value: txn.description)
            
            Divider().background(AppColors.border)
            
            // Reference Code
            if let refCode = txn.paymentTransactionId {
                TransactionDetailRow(label: "Reference", value: refCode, isCopyable: true) {
                    copyToClipboard(refCode)
                }
                Divider().background(AppColors.border)
            }
            
            // Date
            TransactionDetailRow(label: "Date", value: formattedFullDate(txn.createdAt))
            
            Divider().background(AppColors.border)
            
            // Time
            TransactionDetailRow(label: "Time", value: formattedTime(txn.createdAt))
            
            // Payment Method
            if let method = txn.paymentMethod {
                Divider().background(AppColors.border)
                TransactionDetailRow(label: "Payment Method", value: method.displayName, icon: method.icon)
            }
            
            // Gym (for bookings)
            if let gymName = txn.gymName {
                Divider().background(AppColors.border)
                TransactionDetailRow(label: "Gym", value: gymName, icon: "dumbbell.fill")
            }
            
            // Balance Info
            Divider().background(AppColors.border)
            TransactionDetailRow(label: "Balance Before", value: "€\(String(format: "%.2f", txn.balanceBefore))")
            
            Divider().background(AppColors.border)
            TransactionDetailRow(label: "Balance After", value: "€\(String(format: "%.2f", txn.balanceAfter))")
        }
        .glassBackground(cornerRadius: CornerRadii.lg)
    }
    
    // MARK: - Actions Section
    
    private func actionsSection(_ txn: WalletTransaction) -> some View {
        VStack(spacing: Spacing.md) {
            // Copy Reference Button
            if let refCode = txn.paymentTransactionId {
                Button {
                    DemoTapLogger.log("TransactionDetail.CopyReference")
                    copyToClipboard(refCode)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Reference Code")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .glassBackground(cornerRadius: CornerRadii.md)
                }
            }
            
            // View Booking (for payment transactions)
            if txn.type == .payment, txn.bookingId != nil {
                Button {
                    DemoTapLogger.log("TransactionDetail.ViewBooking")
                    if let bookingId = txn.bookingId {
                        router.pushBookingDetail(bookingId: bookingId)
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("View Booking")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
            }
            
            // Request Refund (for completed payments)
            if txn.type == .payment && txn.status == .completed {
                Button {
                    DemoTapLogger.logNoOp("TransactionDetail.RequestRefund")
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Request Refund")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .glassBackground(cornerRadius: CornerRadii.md)
                }
            }
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Transaction not found")
                .font(AppFonts.h5)
                .foregroundColor(AppColors.textHigh)
            
            Button("Go Back") {
                router.pop()
            }
            .font(AppFonts.label)
            .foregroundColor(AppColors.brand)
        }
    }
    
    // MARK: - Helpers
    
    private func loadTransaction() async {
        // If we have a preloaded transaction, use it
        if preloadedTransaction != nil {
            isLoading = false
            return
        }
        
        // Otherwise try to fetch from service
        do {
            let transactions = try await appContainer.walletService.fetchTransactions()
            transaction = transactions.first { $0.id == transactionId }
        } catch {
            print("Failed to load transaction: \(error)")
        }
        
        isLoading = false
    }
    
    private func statusColor(_ status: TransactionStatus) -> Color {
        switch status {
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
    
    private func formattedFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showCopiedAlert = true
    }
}

// MARK: - Transaction Detail Row Component

struct TransactionDetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var isCopyable: Bool = false
    var onCopy: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
            
            Spacer()
            
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.brand)
                }
                
                Text(value)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textHigh)
                
                if isCopyable {
                    Button {
                        onCopy?()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.brand)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(transactionId: "txn_001")
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
