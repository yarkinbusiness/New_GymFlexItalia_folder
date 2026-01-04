//
//  WaveformView.swift
//  Gym Flex Italia
//
//  Lightweight audio waveform visualizer for voice dictation.
//  Displays animated bars that respond to audio level input.
//

import SwiftUI

/// Audio waveform visualizer with smoothly animated bars
/// Used in voice dictation listening state
struct WaveformView: View {
    
    /// Audio level input (0.0 - 1.0)
    let level: Double
    
    /// Number of bars to display
    var barCount: Int = 12
    
    /// Maximum bar height
    var maxHeight: CGFloat = 24
    
    /// Bar width
    var barWidth: CGFloat = 3
    
    /// Spacing between bars
    var spacing: CGFloat = 3
    
    /// Bar color
    var color: Color = .white
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    level: level,
                    barIndex: index,
                    totalBars: barCount,
                    maxHeight: maxHeight,
                    barWidth: barWidth,
                    color: color
                )
            }
        }
    }
}

// MARK: - Individual Bar

private struct WaveformBar: View {
    let level: Double
    let barIndex: Int
    let totalBars: Int
    let maxHeight: CGFloat
    let barWidth: CGFloat
    let color: Color
    
    /// Creates organic wave pattern by offsetting each bar's animation
    private var phaseOffset: Double {
        Double(barIndex) / Double(totalBars) * .pi * 2
    }
    
    /// Calculates the bar height based on level and position
    private var barHeight: CGFloat {
        // Create a wave pattern across bars
        let wave = sin(phaseOffset + level * .pi * 2) * 0.5 + 0.5
        
        // Combine wave pattern with overall level
        let combinedLevel = (wave * 0.6 + level * 0.4)
        
        // Minimum height ensures bars are always visible
        let minHeight: CGFloat = 4
        let dynamicHeight = CGFloat(combinedLevel) * maxHeight
        
        return max(minHeight, dynamicHeight)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: barWidth / 2)
            .fill(color.opacity(0.9))
            .frame(width: barWidth, height: barHeight)
            .animation(.easeInOut(duration: 0.15), value: level)
    }
}

// MARK: - Preview

#Preview("Waveform - Active") {
    ZStack {
        Color.black
        WaveformView(level: 0.7)
    }
    .frame(height: 60)
}

#Preview("Waveform - Low") {
    ZStack {
        Color.black
        WaveformView(level: 0.2)
    }
    .frame(height: 60)
}
