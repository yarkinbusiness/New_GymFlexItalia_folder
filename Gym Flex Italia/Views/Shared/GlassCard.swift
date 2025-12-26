//
//  GlassCard.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Glass morphism card component using LED design system
struct GlassCard<Content: View>: View {
    
    let content: Content
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = CornerRadii.lg
    
    init(padding: CGFloat = Spacing.md, cornerRadius: CGFloat = CornerRadii.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassBackground(cornerRadius: cornerRadius)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading) {
                    Text("Glass Card")
                        .font(AppFonts.h3)
                        .foregroundColor(AppColors.textHigh)
                    Text("This is a glass morphism card with LED design")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textDim)
                }
            }
        }
        .padding()
    }
}
