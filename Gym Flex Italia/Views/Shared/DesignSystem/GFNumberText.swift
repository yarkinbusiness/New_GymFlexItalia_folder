//
//  GFNumberText.swift
//  Gym Flex Italia
//
//  Design System: Animated numeric text with smooth transitions
//

import SwiftUI

/// Animated numeric text that transitions smoothly between values
struct GFNumberText: View {
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let value: Double
    let formatStyle: FormatStyle
    let font: Font
    let color: Color
    let animate: Bool
    
    enum FormatStyle {
        case currency(code: String)
        case decimal(places: Int)
        case integer
        case custom((Double) -> String)
    }
    
    init(
        value: Double,
        formatStyle: FormatStyle = .decimal(places: 2),
        font: Font = .body,
        color: Color = .primary,
        animate: Bool = true
    ) {
        self.value = value
        self.formatStyle = formatStyle
        self.font = font
        self.color = color
        self.animate = animate
    }
    
    /// Whether to actually animate (respects Reduce Motion)
    private var shouldAnimate: Bool {
        animate && !reduceMotion
    }
    
    var body: some View {
        if shouldAnimate {
            // Animated version
            Text(formattedValue)
                .font(font)
                .foregroundColor(color)
                .contentTransition(.numericText(value: value))
                .animation(GFMotion.gentle, value: value)
        } else {
            // Static version (Reduce Motion enabled)
            Text(formattedValue)
                .font(font)
                .foregroundColor(color)
        }
    }
    
    private var formattedValue: String {
        switch formatStyle {
        case .currency(let code):
            if code == "EUR" || code == "€" {
                return String(format: "€%.2f", value)
            }
            return String(format: "%@%.2f", code, value)
        case .decimal(let places):
            return String(format: "%.\(places)f", value)
        case .integer:
            return String(format: "%.0f", value)
        case .custom(let formatter):
            return formatter(value)
        }
    }
}

/// Convenience initializer for currency amounts
extension GFNumberText {
    static func euros(_ amount: Double, font: Font = .body, color: Color = .primary) -> GFNumberText {
        GFNumberText(value: amount, formatStyle: .currency(code: "EUR"), font: font, color: color)
    }
    
    static func fromCents(_ cents: Int, font: Font = .body, color: Color = .primary) -> GFNumberText {
        GFNumberText(value: Double(cents) / 100.0, formatStyle: .currency(code: "EUR"), font: font, color: color)
    }
}

// MARK: - Preview

#Preview("Number Text") {
    VStack(spacing: 20) {
        GFNumberText(value: 125.50, formatStyle: .currency(code: "EUR"), font: .largeTitle.bold())
        GFNumberText(value: 4.5, formatStyle: .decimal(places: 1), font: .title2)
        GFNumberText(value: 42, formatStyle: .integer, font: .headline)
    }
    .padding()
}
