//
//  PaymentMethodsView.swift
//  Gym Flex Italia
//
//  View for managing payment methods.
//

import SwiftUI

/// View for managing payment methods
struct PaymentMethodsView: View {
    
    @EnvironmentObject var router: AppRouter
    @ObservedObject var paymentStore = PaymentMethodsStore.shared
    
    @State private var showDeleteConfirmation = false
    @State private var cardToDelete: PaymentMethodItem?
    
    var body: some View {
        List {
            // Apple Pay Section
            Section {
                applePayRow
            } header: {
                Text("Digital Wallets")
            }
            
            // Cards Section
            Section {
                if paymentStore.cards.isEmpty {
                    noCardsRow
                } else {
                    ForEach(paymentStore.cards) { card in
                        cardRow(card)
                    }
                    .onDelete(perform: deleteCards)
                }
                
                addCardButton
            } header: {
                Text("Credit & Debit Cards")
            } footer: {
                Text("Your card information is stored securely on this device.")
            }
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Remove Card",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let card = cardToDelete {
                    DemoTapLogger.log("PaymentMethods.RemoveCard.\(card.id)")
                    paymentStore.remove(id: card.id)
                }
                cardToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                cardToDelete = nil
            }
        } message: {
            if let card = cardToDelete {
                Text("Remove \(card.displayName)? This cannot be undone.")
            }
        }
    }
    
    // MARK: - Apple Pay Row
    
    private var applePayRow: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "applelogo")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Pay")
                    .font(AppFonts.body)
                    .foregroundColor(.primary)
                
                if ApplePayAvailability.isAvailable() {
                    Text("Available")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.success)
                } else {
                    Text("Not available on this device")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if ApplePayAvailability.isAvailable() {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.success)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - No Cards Row
    
    private var noCardsRow: some View {
        HStack {
            Spacer()
            
            VStack(spacing: Spacing.sm) {
                Image(systemName: "creditcard")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                
                Text("No cards saved")
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.lg)
            
            Spacer()
        }
    }
    
    // MARK: - Card Row
    
    private func cardRow(_ card: PaymentMethodItem) -> some View {
        Button {
            DemoTapLogger.log("PaymentMethods.SetDefault.\(card.id)")
            paymentStore.setDefault(id: card.id)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(brandColor(for: card))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.sm) {
                        Text(card.displayName)
                            .font(AppFonts.body)
                            .foregroundColor(.primary)
                        
                        if card.isDefault {
                            Text("Default")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.success.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let subtitle = card.subtitle {
                        Text(subtitle)
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if card.isDefault {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.success)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                cardToDelete = card
                showDeleteConfirmation = true
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Add Card Button
    
    private var addCardButton: some View {
        Button {
            DemoTapLogger.log("PaymentMethods.AddCard")
            router.pushAddCard()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.brand)
                
                Text("Add Card")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.brand)
            }
        }
    }
    
    // MARK: - Delete Handler
    
    private func deleteCards(at offsets: IndexSet) {
        let cards = paymentStore.cards
        for index in offsets {
            let card = cards[index]
            cardToDelete = card
            showDeleteConfirmation = true
            break // Only handle one at a time
        }
    }
    
    // MARK: - Helpers
    
    private func brandColor(for card: PaymentMethodItem) -> Color {
        guard let brand = card.cardBrand else { return AppColors.brand }
        
        switch brand {
        case .visa:
            return Color(red: 0.09, green: 0.31, blue: 0.61) // Visa blue
        case .mastercard:
            return Color(red: 0.93, green: 0.47, blue: 0.12) // Mastercard orange
        case .amex:
            return Color(red: 0.0, green: 0.47, blue: 0.75) // Amex blue
        }
    }
}

#Preview {
    NavigationStack {
        PaymentMethodsView()
    }
    .environmentObject(AppRouter())
}
