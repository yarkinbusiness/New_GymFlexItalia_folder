//
//  AddCardView.swift
//  Gym Flex Italia
//
//  View for adding a new mock credit/debit card.
//

import SwiftUI

/// View for adding a new payment card
struct AddCardView: View {
    
    @EnvironmentObject var router: AppRouter
    @ObservedObject var paymentStore = PaymentMethodsStore.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form State
    @State private var selectedBrand: CardBrand = .visa
    @State private var last4: String = ""
    @State private var expiryMonth: Int = 1
    @State private var expiryYear: Int = Calendar.current.component(.year, from: Date())
    @State private var setAsDefault: Bool = false
    
    // Validation State
    @State private var validationError: String?
    @State private var showSuccessToast = false
    @State private var isSaving = false
    
    // Expiry options
    private let months = Array(1...12)
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 15))
    }
    
    var body: some View {
        Form {
            // Card Brand
            Section {
                Picker("Card Brand", selection: $selectedBrand) {
                    ForEach(CardBrand.allCases, id: \.self) { brand in
                        Text(brand.displayName).tag(brand)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Card Type")
            }
            
            // Card Number (last 4)
            Section {
                TextField("Last 4 Digits", text: $last4)
                    .keyboardType(.numberPad)
                    .onChange(of: last4) { _, newValue in
                        // Allow only digits, max 4
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count <= 4 {
                            last4 = filtered
                        } else {
                            last4 = String(filtered.prefix(4))
                        }
                        validationError = nil
                    }
            } header: {
                Text("Card Number")
            } footer: {
                Text("For demo purposes, enter any 4 digits.")
            }
            
            // Expiry Date
            Section {
                HStack {
                    Picker("Month", selection: $expiryMonth) {
                        ForEach(months, id: \.self) { month in
                            Text(String(format: "%02d", month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    
                    Text("/")
                        .foregroundColor(.secondary)
                    
                    Picker("Year", selection: $expiryYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
            } header: {
                Text("Expiry Date")
            }
            
            // Default Toggle
            Section {
                Toggle("Set as default payment method", isOn: $setAsDefault)
            }
            
            // Validation Error
            if let error = validationError {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.danger)
                        
                        Text(error)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.danger)
                    }
                }
            }
            
            // Preview
            Section {
                cardPreview
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Add Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveCard()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(!isValid || isSaving)
            }
        }
        .toast("Card added!", isPresented: $showSuccessToast)
    }
    
    // MARK: - Card Preview
    
    private var cardPreview: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadii.sm)
                    .fill(brandColor)
                    .frame(width: 50, height: 35)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(previewDisplayName)
                    .font(AppFonts.body)
                    .foregroundColor(.primary)
                
                Text(previewExpiry)
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if setAsDefault {
                Text("Default")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.success.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        last4.count == 4 && last4.allSatisfy { $0.isNumber }
    }
    
    private var previewDisplayName: String {
        let last4Display = last4.isEmpty ? "••••" : last4.padding(toLength: 4, withPad: "•", startingAt: 0)
        return "\(selectedBrand.displayName) •••• \(last4Display)"
    }
    
    private var previewExpiry: String {
        let monthStr = String(format: "%02d", expiryMonth)
        let yearStr = String(format: "%02d", expiryYear % 100)
        return "Exp \(monthStr)/\(yearStr)"
    }
    
    private var brandColor: Color {
        switch selectedBrand {
        case .visa:
            return Color(red: 0.09, green: 0.31, blue: 0.61)
        case .mastercard:
            return Color(red: 0.93, green: 0.47, blue: 0.12)
        case .amex:
            return Color(red: 0.0, green: 0.47, blue: 0.75)
        }
    }
    
    // MARK: - Actions
    
    private func saveCard() {
        // Validate
        guard last4.count == 4 else {
            validationError = "Please enter exactly 4 digits."
            return
        }
        
        guard last4.allSatisfy({ $0.isNumber }) else {
            validationError = "Card number must contain only digits."
            return
        }
        
        // Check expiry is not in past
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if expiryYear < currentYear || (expiryYear == currentYear && expiryMonth < currentMonth) {
            validationError = "Expiry date must be in the future."
            return
        }
        
        isSaving = true
        
        // Create card
        let card = PaymentMethodItem.card(
            brand: selectedBrand,
            last4: last4,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            isDefault: setAsDefault
        )
        
        // Save
        paymentStore.upsert(card)
        
        DemoTapLogger.log("AddCard.Saved", context: "brand: \(selectedBrand.rawValue), last4: \(last4)")
        
        // Show success and pop
        showSuccessToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            router.pop()
        }
    }
}

#Preview {
    NavigationStack {
        AddCardView()
    }
    .environmentObject(AppRouter())
}
