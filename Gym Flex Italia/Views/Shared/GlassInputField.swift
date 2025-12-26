//
//  GlassInputField.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import SwiftUI
import UIKit

/// Reusable glass morphism input field component
struct GlassInputField: View {
    var title: String? = nil
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let title = title {
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textDim)
            }
            
            HStack(spacing: Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(title != nil ? AppColors.textDim : AppColors.accent)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .textContentType(textContentType)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .textInputAutocapitalization(autocapitalization)
                            .disableAutocorrection(true)
                    }
                }
                .font(title != nil ? AppFonts.body : AppFonts.body)
                .foregroundColor(AppColors.textHigh)
            }
            .padding(.vertical, title != nil ? Spacing.md : Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .glassBackground(
                cornerRadius: CornerRadii.md,
                opacity: 0.3,
                blur: 18,
                borderOpacity: title != nil ? 0.12 : 0.2
            )
        }
    }
}

