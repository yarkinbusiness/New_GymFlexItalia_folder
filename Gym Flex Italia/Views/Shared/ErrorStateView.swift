//
//  ErrorStateView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Error state view with retry action
struct ErrorStateView: View {
    
    let title: String
    let message: String
    let icon: String
    let retryAction: (() -> Void)?
    
    init(
        title: String = "Something went wrong",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                PrimaryButton("Try Again", icon: "arrow.clockwise") {
                    retryAction()
                }
                .frame(maxWidth: 200)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Inline error message
struct InlineErrorView: View {
    
    let message: String
    var dismissAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorStateView(
            message: "Unable to load data. Please check your internet connection and try again."
        ) {
            print("Retry tapped")
        }
        
        Divider()
        
        InlineErrorView(
            message: "Failed to update profile",
            dismissAction: {
                print("Dismiss")
            }
        )
        .padding()
    }
}

