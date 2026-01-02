//
//  GFProgressRing.swift
//  Gym Flex Italia
//
//  Design System: Circular progress ring with smooth animation
//

import SwiftUI

/// Circular progress ring with smooth animated transitions
struct GFProgressRing: View {
    
    @Environment(\.gfTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let showLabel: Bool
    let animate: Bool
    
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 100,
        showLabel: Bool = false,
        animate: Bool = true
    ) {
        self.progress = max(0, min(1, progress)) // Clamp to 0...1
        self.lineWidth = lineWidth
        self.size = size
        self.showLabel = showLabel
        self.animate = animate
    }
    
    /// Whether to actually animate (respects Reduce Motion)
    private var shouldAnimate: Bool {
        animate && !reduceMotion
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    theme.colors.surface2,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    theme.colors.primary.opacity(0.85),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(shouldAnimate ? GFMotion.live : nil, value: progress)
            
            // Optional center label
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
                    .if(shouldAnimate) { view in
                        view
                            .contentTransition(.numericText())
                            .animation(GFMotion.gentle, value: progress)
                    }
            }
        }
        .frame(width: size, height: size)
    }
}

/// Compact progress ring variant for inline use
struct GFProgressRingCompact: View {
    
    @Environment(\.gfTheme) private var theme
    
    let progress: Double
    let color: Color?
    
    init(progress: Double, color: Color? = nil) {
        self.progress = max(0, min(1, progress))
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    (color ?? theme.colors.primary).opacity(0.85),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(GFMotion.live, value: progress)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    VStack(spacing: 30) {
        GFProgressRing(progress: 0.75, showLabel: true)
        
        GFProgressRing(progress: 0.5, lineWidth: 12, size: 150, showLabel: true)
        
        HStack(spacing: 20) {
            GFProgressRingCompact(progress: 0.25)
            GFProgressRingCompact(progress: 0.5, color: .green)
            GFProgressRingCompact(progress: 0.75, color: .orange)
            GFProgressRingCompact(progress: 1.0, color: .red)
        }
    }
    .padding()
    .withGFTheme()
}
