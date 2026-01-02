//
//  GFCard.swift
//  Gym Flex Italia
//
//  Design System: Card container component
//

import SwiftUI

/// Design System card container with premium styling
struct GFCard<Content: View>: View {
    
    @Environment(\.gfTheme) private var theme
    
    let content: Content
    let padding: CGFloat
    let showShadow: Bool
    let showBorder: Bool
    let elevated: Bool
    
    init(
        padding: CGFloat = GFSpacing.xl, // Increased default padding
        showShadow: Bool = true,
        showBorder: Bool = true,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.showShadow = showShadow
        self.showBorder = showBorder
        self.elevated = elevated
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(elevated ? theme.colors.surfaceElevated : theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: GFCorners.card))
            .overlay(
                RoundedRectangle(cornerRadius: GFCorners.card)
                    .stroke(theme.colors.border, lineWidth: showBorder ? 1 : 0)
            )
            .if(showShadow) { view in
                view.gfCardShadow()
            }
    }
}

/// Card with optional header - premium styling
struct GFCardWithHeader<Content: View>: View {
    
    @Environment(\.gfTheme) private var theme
    
    let title: String
    let icon: String?
    let content: Content
    let padding: CGFloat
    let showShadow: Bool
    let showBorder: Bool
    
    init(
        title: String,
        icon: String? = nil,
        padding: CGFloat = GFSpacing.xl, // Increased default padding
        showShadow: Bool = true,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.padding = padding
        self.showShadow = showShadow
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: GFSpacing.lg) {
            // Header
            HStack(spacing: GFSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.colors.primary)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            // Content
            content
        }
        .padding(padding)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: GFCorners.card))
        .overlay(
            RoundedRectangle(cornerRadius: GFCorners.card)
                .stroke(theme.colors.border, lineWidth: showBorder ? 1 : 0)
        )
        .if(showShadow) { view in
            view.gfCardShadow()
        }
    }
}

// MARK: - Conditional Modifier

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Previews

#Preview("Card") {
    VStack(spacing: GFSpacing.lg) {
        GFCard {
            VStack(alignment: .leading, spacing: GFSpacing.sm) {
                Text("Sample Card")
                    .gfTitle()
                Text("This is a card with default styling")
                    .gfBody()
                    .foregroundStyle(.secondary)
            }
        }
        
        GFCardWithHeader(title: "Active Session", icon: "bolt.fill") {
            Text("Session content here")
                .gfBody()
        }
    }
    .padding()
    .withGFTheme()
}
