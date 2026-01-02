//
//  GFButton.swift
//  Gym Flex Italia
//
//  Design System: Button component
//

import SwiftUI

/// Button style variants
enum GFButtonStyle {
    case primary
    case secondary
}

/// Design System button component
struct GFButton: View {
    
    @Environment(\.gfTheme) private var theme
    @State private var isPressed = false
    
    let title: String
    let icon: String?
    let style: GFButtonStyle
    let isDisabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: GFButtonStyle = .primary,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: GFSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GFSpacing.md)
            .padding(.horizontal, GFSpacing.lg)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: GFCorners.button))
        }
        .buttonStyle(GFButtonPressStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return theme.colors.primary
        case .secondary:
            return theme.colors.surface2
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return theme.colors.primary
        }
    }
}

/// Custom button style with press animation
struct GFButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(GFMotion.gentle, value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: GFSpacing.lg) {
        GFButton("Primary Button", icon: "checkmark") {}
        
        GFButton("Secondary Button", style: .secondary) {}
        
        GFButton("Loading", isLoading: true) {}
        
        GFButton("Disabled", isDisabled: true) {}
    }
    .padding()
    .withGFTheme()
}
