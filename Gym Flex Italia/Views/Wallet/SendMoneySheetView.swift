//
//  SendMoneySheetView.swift
//  Gym Flex Italia
//
//  Demo sheet for sending money (placeholder for future implementation)
//

import SwiftUI

/// Sheet for sending money to other users (demo mode)
struct SendMoneySheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.gfTheme) private var theme
    
    @State private var recipient: String = ""
    @State private var amountText: String = ""
    @State private var showDemoAlert = false
    
    // Validation
    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amountText) ?? 0) > 0
    }
    
    private var amount: Double {
        Double(amountText) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: GFSpacing.xl) {
                // Header illustration
                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.colors.primary)
                    .padding(.top, GFSpacing.xl)
                
                // Form fields
                VStack(spacing: GFSpacing.lg) {
                    // Recipient field
                    VStack(alignment: .leading, spacing: GFSpacing.sm) {
                        Text("Recipient")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        TextField("Email or username", text: $recipient)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(GFSpacing.lg)
                            .background(theme.colors.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: GFCorners.medium))
                    }
                    
                    // Amount field
                    VStack(alignment: .leading, spacing: GFSpacing.sm) {
                        Text("Amount")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        HStack(spacing: GFSpacing.sm) {
                            Text("€")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, weight: .semibold))
                        }
                        .padding(GFSpacing.lg)
                        .background(theme.colors.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: GFCorners.medium))
                    }
                }
                .padding(.horizontal, GFSpacing.lg)
                
                Spacer()
                
                // Send button
                Button {
                    DemoTapLogger.log("Wallet.Send.Submit", context: "recipient: \(recipient), amount: \(amountText)")
                    showDemoAlert = true
                } label: {
                    Text("Send €\(String(format: "%.2f", amount))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? theme.colors.primary : theme.colors.primary.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: GFCorners.medium))
                }
                .disabled(!isValid)
                .padding(.horizontal, GFSpacing.lg)
                .padding(.bottom, GFSpacing.xl)
            }
            .background(theme.colors.surface0.ignoresSafeArea())
            .navigationTitle("Send Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Coming Soon", isPresented: $showDemoAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Sending money to other users is not available yet. This feature will be enabled in a future update.")
            }
        }
    }
}

#Preview {
    SendMoneySheetView()
        .withGFTheme()
}
