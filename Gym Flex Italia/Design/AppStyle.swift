//
//  AppStyle.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import SwiftUI

// MARK: - Color + Gradient System
enum AppColors {
    // Brand
    static let brand = Color(red: 141 / 255, green: 76 / 255, blue: 244 / 255)
    static let accent = Color(red: 20 / 255, green: 200 / 255, blue: 240 / 255)
    
    // Semantic
    static let success = Color(red: 59 / 255, green: 222 / 255, blue: 128 / 255)
    static let warning = Color(red: 249 / 255, green: 213 / 255, blue: 53 / 255)
    static let danger = Color(red: 242 / 255, green: 46 / 255, blue: 46 / 255)
    
    // Background
    static let background = Color(red: 15 / 255, green: 15 / 255, blue: 16 / 255)
    static let card = Color(red: 24 / 255, green: 24 / 255, blue: 26 / 255)
    static let secondary = Color(red: 36 / 255, green: 37 / 255, blue: 39 / 255)
    
    // Text
    static let textHigh = Color.white
    static let textMedium = Color(red: 211 / 255, green: 212 / 255, blue: 216 / 255)
    static let textDim = Color(red: 166 / 255, green: 167 / 255, blue: 171 / 255)
    
    // Borders
    static let border = Color(red: 48 / 255, green: 49 / 255, blue: 52 / 255)
}

struct AppGradients {
    static let primary = LinearGradient(
        colors: [AppColors.brand, AppColors.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let background = LinearGradient(
        colors: [
            Color(red: 7 / 255, green: 7 / 255, blue: 10 / 255),
            AppColors.background
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing & Radii
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadii {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let pill: CGFloat = 999
}

// MARK: - Typography Helpers
enum AppFonts {
    static let h1 = Font.system(size: 32, weight: .semibold)
    static let h2 = Font.system(size: 28, weight: .semibold)
    static let h3 = Font.system(size: 24, weight: .semibold)
    static let h4 = Font.system(size: 20, weight: .semibold)
    static let h5 = Font.system(size: 18, weight: .semibold)
    static let h6 = Font.system(size: 16, weight: .semibold)
    
    static let body = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    
    static let label = Font.system(size: 15, weight: .semibold)
    static let caption = Font.system(size: 12, weight: .medium)
}

// MARK: - Glass Effect
struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = CornerRadii.lg
    var opacity: Double = 0.35
    var blur: CGFloat = 25
    var borderOpacity: Double = 0.12
    
    func body(content: Content) -> some View {
        content
            .background(
                AppColors.card
                    .opacity(opacity)
                    .blur(radius: blur)
            )
            .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppColors.border.opacity(borderOpacity), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassBackground(
        cornerRadius: CGFloat = CornerRadii.lg,
        opacity: Double = 0.35,
        blur: CGFloat = 25,
        borderOpacity: Double = 0.12
    ) -> some View {
        modifier(
            GlassModifier(
                cornerRadius: cornerRadius,
                opacity: opacity,
                blur: blur,
                borderOpacity: borderOpacity
            )
        )
    }
}

// MARK: - UIKit Blur Helper
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

