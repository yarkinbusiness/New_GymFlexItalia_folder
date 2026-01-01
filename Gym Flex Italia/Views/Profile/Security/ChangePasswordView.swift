//
//  ChangePasswordView.swift
//  Gym Flex Italia
//
//  Mock change password view.
//

import SwiftUI

/// Change password view (mock implementation)
struct ChangePasswordView: View {
    
    @EnvironmentObject var router: AppRouter
    @ObservedObject var securityStore = SecuritySettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form State
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    // UI State
    @State private var validationError: String?
    @State private var showSuccess = false
    @State private var isSaving = false
    
    var body: some View {
        Form {
            // Current Password
            Section {
                SecureField("Current Password", text: $currentPassword)
                    .textContentType(.password)
                    .onChange(of: currentPassword) { _, _ in validationError = nil }
            } header: {
                Text("Current Password")
            }
            
            // New Password
            Section {
                SecureField("New Password", text: $newPassword)
                    .textContentType(.newPassword)
                    .onChange(of: newPassword) { _, _ in validationError = nil }
                
                SecureField("Confirm New Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .onChange(of: confirmPassword) { _, _ in validationError = nil }
            } header: {
                Text("New Password")
            } footer: {
                Text("Password must be at least 8 characters long.")
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
            
            // Submit Button
            Section {
                Button {
                    changePassword()
                } label: {
                    HStack {
                        Spacer()
                        
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Change Password")
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, Spacing.sm)
                    .background(isFormValid ? AppColors.brand : Color.gray)
                    .cornerRadius(CornerRadii.md)
                }
                .disabled(!isFormValid || isSaving)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toast("Password changed!", isPresented: $showSuccess)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }
    
    // MARK: - Actions
    
    private func changePassword() {
        // Validate current password
        guard !currentPassword.isEmpty else {
            validationError = "Please enter your current password."
            return
        }
        
        // Validate new password length
        guard newPassword.count >= 8 else {
            validationError = "New password must be at least 8 characters."
            return
        }
        
        // Validate passwords match
        guard newPassword == confirmPassword else {
            validationError = "New passwords do not match."
            return
        }
        
        // Mock: In a real app, verify current password
        // For demo purposes, we just simulate success
        
        isSaving = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            
            // Update last password change date
            securityStore.lastPasswordChangeAt = Date()
            
            DemoTapLogger.log("Security.PasswordChanged")
            
            showSuccess = true
            
            // Pop back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                router.pop()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
    .environmentObject(AppRouter())
}
