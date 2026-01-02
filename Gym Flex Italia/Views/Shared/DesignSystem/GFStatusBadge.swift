//
//  GFStatusBadge.swift
//  Gym Flex Italia
//
//  Design System: Status badge component
//

import SwiftUI

/// Badge style variants
enum GFBadgeStyle {
    case success
    case warning
    case danger
    case info
}

/// Design System status badge
struct GFStatusBadge: View {
    
    @Environment(\.gfTheme) private var theme
    
    let text: String
    let style: GFBadgeStyle
    let icon: String?
    
    init(
        _ text: String,
        style: GFBadgeStyle = .info,
        icon: String? = nil
    ) {
        self.text = text
        self.style = style
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: GFSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
            }
            
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, GFSpacing.sm)
        .padding(.vertical, GFSpacing.xs)
        .background(backgroundColor.opacity(0.15))
        .foregroundColor(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: GFCorners.chip))
    }
    
    private var backgroundColor: Color {
        switch style {
        case .success: return theme.colors.success
        case .warning: return theme.colors.warning
        case .danger: return theme.colors.danger
        case .info: return theme.colors.primary
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .success: return theme.colors.success
        case .warning: return theme.colors.warning
        case .danger: return theme.colors.danger
        case .info: return theme.colors.primary
        }
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: GFSpacing.lg) {
        GFStatusBadge("Active", style: .success, icon: "checkmark.circle.fill")
        GFStatusBadge("Pending", style: .warning, icon: "clock.fill")
        GFStatusBadge("Expired", style: .danger, icon: "xmark.circle.fill")
        GFStatusBadge("Info", style: .info, icon: "info.circle.fill")
    }
    .padding()
    .withGFTheme()
}
