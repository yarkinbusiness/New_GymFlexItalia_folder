//
//  PrimaryButton.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Primary button component matching LED design
struct PrimaryButton: View {
    
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppColors.brand
            case .secondary: return AppColors.secondary
            case .destructive: return AppColors.danger
            case .ghost: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary, .ghost: return AppColors.textHigh
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AppFonts.label)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(style.foregroundColor)
            .background(
                Group {
                    if style == .primary {
                        AppGradients.primary
                    } else if style == .ghost {
                        Color.clear
                    } else {
                        style.backgroundColor
                    }
                }
            )
            .overlay(
                style == .ghost ?
                    AnyView(
                        RoundedRectangle(cornerRadius: CornerRadii.md)
                            .stroke(AppColors.brand, lineWidth: 2)
                    ) :
                    AnyView(EmptyView())
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            .shadow(
                color: style == .primary ? AppColors.brand.opacity(0.3) : Color.clear,
                radius: style == .primary ? 15 : 0,
                x: 0,
                y: style == .primary ? 8 : 0
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: 16) {
            PrimaryButton("Sign In", icon: "arrow.right") {}
            PrimaryButton("Loading", isLoading: true) {}
            PrimaryButton("Disabled", isDisabled: true) {}
            PrimaryButton("Secondary", style: .secondary) {}
            PrimaryButton("Destructive", style: .destructive) {}
            PrimaryButton("Ghost", style: .ghost) {}
        }
        .padding()
    }
}
