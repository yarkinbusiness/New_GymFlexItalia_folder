//
//  InlineErrorBanner.swift
//  Gym Flex Italia
//
//  Reusable inline error banner component
//

import SwiftUI

/// A reusable inline error/warning banner
/// Shows a dismissible message with icon
struct InlineErrorBanner: View {
    
    let message: String
    var type: BannerType = .error
    var onDismiss: (() -> Void)?
    
    enum BannerType {
        case error
        case warning
        case info
        case success
        
        var iconName: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            case .success: return .green
            }
        }
        
        var backgroundColor: Color {
            color.opacity(0.15)
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: type.iconName)
                .foregroundColor(type.color)
                .font(.system(size: 18))
            
            Text(message)
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textHigh)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textDim)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(Spacing.md)
        .background(type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
    }
}

/// Convenience view for common error banner use case
struct ErrorBannerView: View {
    @Binding var errorMessage: String?
    
    var body: some View {
        if let message = errorMessage {
            InlineErrorBanner(
                message: message,
                type: .warning,
                onDismiss: { errorMessage = nil }
            )
        }
    }
}

/// Success confirmation banner
struct SuccessBanner: View {
    let message: String
    var onDismiss: (() -> Void)?
    
    var body: some View {
        InlineErrorBanner(
            message: message,
            type: .success,
            onDismiss: onDismiss
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        InlineErrorBanner(
            message: "Something went wrong. Please try again.",
            type: .error,
            onDismiss: {}
        )
        
        InlineErrorBanner(
            message: "Your session is about to expire.",
            type: .warning,
            onDismiss: {}
        )
        
        InlineErrorBanner(
            message: "New features are available!",
            type: .info,
            onDismiss: nil
        )
        
        InlineErrorBanner(
            message: "Booking confirmed successfully!",
            type: .success,
            onDismiss: {}
        )
    }
    .padding()
}
