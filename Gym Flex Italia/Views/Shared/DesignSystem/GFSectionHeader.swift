//
//  GFSectionHeader.swift
//  Gym Flex Italia
//
//  Design System: Section header component
//

import SwiftUI

/// Design System section header
struct GFSectionHeader: View {
    
    @Environment(\.gfTheme) private var theme
    
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        _ title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .gfSection()
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.primary)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Section Headers") {
    VStack(spacing: GFSpacing.xl) {
        GFSectionHeader("Nearby Gyms")
        
        GFSectionHeader("Recent Activity", actionTitle: "See All") {
            print("See all tapped")
        }
    }
    .padding()
    .withGFTheme()
}
