//
//  CheckInView.swift
//  Gym Flex Italia
//
//  Manual check-in view with code entry and validation
//

import SwiftUI

/// Manual check-in view for entering check-in codes
struct CheckInView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    
    let bookingId: String
    
    @StateObject private var viewModel = CheckInViewModel()
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Error Banner
                    if let error = viewModel.errorMessage {
                        InlineErrorBanner(
                            message: error,
                            type: .error,
                            onDismiss: { viewModel.clearError() }
                        )
                    }
                    
                    if viewModel.isSuccess {
                        successView
                    } else {
                        // Code Entry
                        codeEntrySection
                        
                        // Submit Button
                        submitButton
                        
                        // Help Section
                        helpSection
                    }
                }
                .padding(Spacing.lg)
                .padding(.bottom, 50)
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingOverlayView(message: "Checking in...")
            }
        }
        .navigationTitle("Check In")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Pre-fill with the booking's check-in code if available
            if let booking = MockBookingStore.shared.bookingById(bookingId),
               let code = booking.checkinCode {
                viewModel.checkInCode = code
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(AppColors.brand)
            
            Text("Enter Check-in Code")
                .font(AppFonts.h3)
                .foregroundColor(.primary)
            
            Text("Enter the code shown on your booking confirmation")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
    }
    
    // MARK: - Code Entry Section
    
    private var codeEntrySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Check-in Code")
                .font(AppFonts.label)
                .foregroundColor(.secondary)
            
            TextField("CHK-XXXXXX", text: $viewModel.checkInCode)
                .font(.system(.title2, design: .monospaced))
                .textFieldStyle(.plain)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .focused($isCodeFieldFocused)
                .padding(Spacing.lg)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadii.md)
                        .stroke(
                            viewModel.isCodeValid ? AppColors.success : Color(.separator),
                            lineWidth: viewModel.isCodeValid ? 2 : 1
                        )
                )
            
            // Validation Hint
            if !viewModel.checkInCode.isEmpty && !viewModel.isCodeValid {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                    Text("Format: CHK- followed by 6 characters")
                        .font(AppFonts.caption)
                }
                .foregroundColor(.orange)
            } else if viewModel.isCodeValid {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Valid code format")
                        .font(AppFonts.caption)
                }
                .foregroundColor(AppColors.success)
            }
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button {
            DemoTapLogger.log("CheckIn.SubmitManual")
            isCodeFieldFocused = false
            
            Task {
                await viewModel.submit(
                    code: viewModel.checkInCode,
                    bookingId: bookingId,
                    using: appContainer.checkInService
                )
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Submit Check-in")
                }
            }
            .font(AppFonts.label)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                viewModel.canSubmit
                    ? AnyShapeStyle(AppGradients.primary)
                    : AnyShapeStyle(Color.gray)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
        }
        .disabled(!viewModel.canSubmit)
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: Spacing.xl) {
            // Success Animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.success)
            
            VStack(spacing: Spacing.sm) {
                Text("Checked In!")
                    .font(AppFonts.h2)
                    .foregroundColor(.primary)
                
                if let result = viewModel.successResult {
                    Text(result.message)
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Check-in time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text(result.checkedInAt.formatted(date: .abbreviated, time: .shortened))
                            .font(AppFonts.body)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.sm)
                }
            }
            
            // Done Button
            Button {
                DemoTapLogger.log("CheckIn.Done")
                router.pop()
            } label: {
                Text("Done")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
        }
        .padding(Spacing.xl)
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Need Help?")
                    .font(AppFonts.label)
                    .foregroundColor(.blue)
            }
            
            Text("Your check-in code can be found in your booking confirmation email or in the Check-in tab of this app. If you're having trouble, please contact gym staff for assistance.")
                .font(AppFonts.bodySmall)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.blue.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadii.md)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
    }
}

#Preview {
    NavigationStack {
        CheckInView(bookingId: "booking_upcoming_001")
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
