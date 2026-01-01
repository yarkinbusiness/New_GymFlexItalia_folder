//
//  DeleteAccountView.swift
//  Gym Flex Italia
//
//  Delete account confirmation view (mock implementation).
//

import SwiftUI

/// Delete account confirmation view
struct DeleteAccountView: View {
    
    @EnvironmentObject var router: AppRouter
    
    @State private var confirmationText: String = ""
    @State private var isDeleting = false
    @State private var showDeleted = false
    
    private let requiredText = "DELETE"
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(AppColors.danger.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.danger)
                }
                .padding(.top, Spacing.xl)
                
                // Warning Text
                VStack(spacing: Spacing.md) {
                    Text("Delete Your Account?")
                        .font(AppFonts.h2)
                        .foregroundColor(.primary)
                    
                    Text("This action is permanent and cannot be undone.")
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // What Will Be Deleted
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("What will be deleted:")
                        .font(AppFonts.h5)
                        .foregroundColor(.primary)
                    
                    deleteItem("Your profile and personal data")
                    deleteItem("Payment methods")
                    deleteItem("Security settings")
                    deleteItem("Booking history")
                    deleteItem("Wallet balance and transactions")
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.lg)
                
                // Confirmation Input
                VStack(spacing: Spacing.md) {
                    Text("Type \"\(requiredText)\" to confirm:")
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $confirmationText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(AppFonts.h3)
                        .multilineTextAlignment(.center)
                        .padding(Spacing.md)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(CornerRadii.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadii.md)
                                .stroke(
                                    confirmationText == requiredText ? AppColors.danger : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                
                // Delete Button
                Button {
                    deleteAccount()
                } label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "trash.fill")
                            Text("Delete Account")
                        }
                    }
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(isConfirmed ? AppColors.danger : Color.gray)
                    .cornerRadius(CornerRadii.md)
                }
                .disabled(!isConfirmed || isDeleting)
                
                // Cancel Link
                Button {
                    router.pop()
                } label: {
                    Text("Cancel")
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDeleted) {
            accountDeletedSheet
        }
    }
    
    // MARK: - Delete Item Row
    
    private func deleteItem(_ text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(AppColors.danger)
            
            Text(text)
                .font(AppFonts.body)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Account Deleted Sheet
    
    private var accountDeletedSheet: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.success)
            }
            
            Text("Account Deleted")
                .font(AppFonts.h2)
                .foregroundColor(.primary)
            
            Text("Your account has been successfully deleted.")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                showDeleted = false
                router.resetToRoot()
            } label: {
                Text("Done")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .cornerRadius(CornerRadii.md)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Computed Properties
    
    private var isConfirmed: Bool {
        confirmationText == requiredText
    }
    
    // MARK: - Actions
    
    private func deleteAccount() {
        guard isConfirmed else { return }
        
        isDeleting = true
        DemoTapLogger.log("Security.DeleteAccount.Confirmed")
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Clear stores
            clearUserData()
            
            isDeleting = false
            showDeleted = true
        }
    }
    
    /// Clear user data from persisted stores
    private func clearUserData() {
        // Keys to clear
        let keysToRemove = [
            "payment_methods_store_v1",    // Payment methods
            "security_settings_store_v1",   // Security settings
            "device_sessions_store_v1",     // Device sessions
            // Optionally clear more (keeping these commented for safety):
            // "wallet_store_v1",            // Wallet
            // "booking_store_v1",           // Bookings
            // "groups_store_v1",            // Groups
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
            print("🗑️ DeleteAccount: Removed \(key)")
        }
        
        // Reset in-memory singletons
        SecuritySettingsStore.shared.reset()
        DeviceSessionsStore.shared.reset()
        PaymentMethodsStore.shared.reset()
        
        print("🗑️ DeleteAccount: User data cleared")
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
    }
    .environmentObject(AppRouter())
}
